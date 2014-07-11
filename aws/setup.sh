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
    ACTIVE=$(./aws.py list_resources | grep worker | wc -l)
    MORE=$1
    for i in $(seq $(($ACTIVE+1)) 1 $(($ACTIVE+$MORE)) )
    do
        echo "Starting worker $i"
        ./aws.py start_worker swift-worker-$i &> $LOG &
    done
    wait
    ./aws.py list_resources
}

stop_headnode()
{
    echo "Stopping headnode"
    ./aws.py stop_headnode
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
    ./aws.py list_resources
}

dissolve()
{
    ./aws.py dissolve
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

init()
{
    source configs
}
init
