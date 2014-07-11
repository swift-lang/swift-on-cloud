#!/bin/bash

LOG=Setup_$$.log

# Is this valid/required for AWS ?
check_project ()
{
    RESULT=$(gcutil listinstances --project=$GCE_PROJECTID 2>&1)
}


start_worker ()
{
    echo "Starting worker - TODO"
}

# Is this valid for AWS ?
check_keys ()
{
    echo "Check_keys - TODO"
    [[ ! -f ~/.ssh/google_compute_engine      ]] && echo "Google private key missing" && return
    [[ ! -f ~/.ssh/google_compute_engine.pub  ]] && echo "Google public key missing"  && return
}


stop_workers()
{
    echo "Stopping all instances"
}


stop_n_workers()
{
    COUNT=1
    [[ ! -z "$1" ]] && COUNT=$1
    echo "Stopping $COUNT instances"
    INSTANCES=$(gcutil --project=$GCE_PROJECTID listinstances | grep worker | awk '{print $2}' | tail -n $COUNT)
    gcutil --project=$GCE_PROJECTID deleteinstance $INSTANCES --delete_boot_pd --force
}


# Start N workers in parallel ?
# This script ensures that only the specified number of workers are active
start_n_workers ()
{
    COUNT=$1
    CURRENT=1
    out=$(gcutil --project=$GCE_PROJECTID listinstances | grep "swift-worker")
    if [[ "$?" == 0 ]]
    then
        echo "Current workers"
        echo "${out[*]}"
        CURRENT=$(gcutil --project=$GCE_PROJECTID listinstances | grep "swift-worker" | wc -l)
        echo "Count : " $CURRENT
        echo "New workers needed : $(($COUNT - $CURRENT))"
    fi

    for i in $(seq $CURRENT 1 $COUNT)
    do
        start_worker $i &> $LOG &
    done
    wait
    gcutil --project=$GCE_PROJECTID listinstances
    echo "Updating WORKER_HOSTS"
    EXTERNAL_IPS=$(gcutil --project=$GCE_PROJECTID listinstances | grep worker | awk '{print $10}')
    WORKER_NAMES=$(gcutil --project=$GCE_PROJECTID listinstances | grep worker | awk '{print $2}')
}

start_n_more ()
{
    setup_images
    ACTIVE=$(gcutil --project=$GCE_PROJECTID listinstances | grep worker | wc -l)
    MORE=$1
    for i in $(seq $(($ACTIVE+1)) 1 $(($ACTIVE+$MORE)) )
    do
        echo "Starting worker $i"
        start_worker $i &> $LOG &
    done
    wait
    gcutil --project=$GCE_PROJECID listinstances
    echo "Updating WORKER_HOSTS"
    EXTERNAL_IPS=$(gcutil --project=$GCE_PROJECTID listinstances | grep worker | awk '{print $10}')
    WORKER_NAMES=$(gcutil --project=$GCE_PROJECTID listinstances | grep worker | awk '{print $2}')
}

stop_headnode()
{
    echo "Stopping headnode"
    gcutil --project=$GCE_PROJECTID deleteinstance "headnode" --delete_boot_pd --force
}

add_image()
{
    gcutil --project=$GCE_PROJECTID addimage $1 $2
}

setup_images()
{
    echo "Checking images"
    IFS=$'\n\r'; image_list=($(gcutil --project=$GCE_PROJECTID listimages | grep -o "swift-[^\ ]*"))
    #echo ${image_list[*]}
    if [[ $HEADNODE_IMAGE == $DEPOT_PREFIX* ]]
    then
        HEADNODE_IMAGE_ID="swift-headnode-image-$(echo ${HEADNODE_IMAGE%.image.tar.gz} | tail -c 6)"
        echo ${image_list[*]} | grep -o $HEADNODE_IMAGE_ID &> /dev/null
        if [[ "$?" == "0" ]]
        then # The image is already added to the project
            echo "$HEADNODE_IMAGE_ID present"
        else # The image is not present and needs to be added
            echo "Adding image $HEADNODE_IMAGE_ID"
            add_image $HEADNODE_IMAGE_ID $HEADNODE_IMAGE
        fi
    else
        echo "Not from swift-worker"
    fi

    if [[ $WORKER_IMAGE == $DEPOT_PREFIX* ]]
    then
        WORKER_IMAGE_ID="swift-worker-image-$(echo ${WORKER_IMAGE%.image.tar.gz} | tail -c 6)"
        echo ${image_list[*]} | grep -o $WORKER_IMAGE_ID &> /dev/null
        if [[ "$?" == "0" ]]
        then # The image is already added to the project
            echo "$WORKER_IMAGE_ID present"
        else # The image is not present and needs to be added
            echo "Adding image $WORKER_IMAGE_ID"
            add_image $WORKER_IMAGE_ID $WORKER_IMAGE
        fi
    else
        echo "Not from $DEPOT_PREFIX"
    fi

}

setup_firewall()
{
    echo "Checking for swift firewall rules"
    gcutil --project=$GCE_PROJECTID listfirewalls | grep swift-ports
    if [[ "$?" == "0" ]]
    then
        echo "Firewall present"
    else
        echo "Creating firewall"
        gcutil --project=$GCE_PROJECTID addfirewall swift-ports --network=default \
            --allowed=tcp:50000-60000,udp:50000-60000 \
            --allowed_ip_sources='0.0.0.0/0'
    fi
}

generate_swiftproperties()
{
    EXTERNAL_IP=$(gcutil --project=$GCE_PROJECTID listinstances | grep headnode | awk '{ print $10 }')
    SERVICE_PORT=50010
    echo http://$EXTERNAL_IP:$SERVICE_PORT > PUBLIC_ADDRESS
    cat <<EOF > swift.properties
site=cloud,local
use.provider.staging=true
execution.retries=2

site.local {
   jobmanager=local
   initialScore=10000
   filesystem=local
   workdir=/tmp/swiftwork
}

site.cloud {
   taskWalltime=04:00:00
   initialScore=10000
   filesystem=local
   jobmanager=coaster-persistent:local:local:http://$EXTERNAL_IP:$SERVICE_PORT
   workerManager=passive
   taskThrottle=800
   workdir=/home/$USER/work
}

EOF
}

list_resources()
{
    gcutil --project=$GCE_PROJECTID listinstances # | grep worker | awk '{print $2}'
}

dissolve()
{
    stop_headnode;
    stop_workers;
}

connect()
{
    source configs
    NODE=$1
    [[ -z $1 ]] && NODE="headnode"
    [[ -z $AWS_USERNAME ]] && AWS_USERNAME="ec2-user"

    IP=$(./aws.py list_resource $NODE)
    echo "Connecting to AWS node:$NODE on $IP as $AWS_USERNAME"
    ssh -A -o StrictHostKeyChecking=no -l $AWS_USERNAME -i $AWS_KEYPAIR_FILE $IP
}
