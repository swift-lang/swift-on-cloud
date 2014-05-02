#!/bin/bash

LOG=Setup_$$.log

start_worker ()
{
    ID=$1;
    if [[ -z $ID ]]
    then
        echo "No ID provided to name worker instance"
        return
    fi
    gcutil --project=$GCE_PROJECTID \
        addinstance swift-worker-$ID \
        --image=$WORKER_IMAGE \
        --zone=$GCE_ZONE \
        --machine_type=$WORKER_MACHINE_TYPE \
        --auto_delete_boot_disk \
        --metadata=startup-script:'#!/bin/bash
CENTRAL="173.255.112.20"
WORKERPORT="50005"
#Ping timeout
PTIMEOUT=4
worker_loop ()
{
    while :
    do
        echo "Pinging headnode"
        ping headnode -w $PTIMEOUT
        if [[ "$?" == "0" ]]
        then
            echo "Headnode present in same network"
            worker.pl http://headnode:$WORKERPORT 0099 ~/workerlog -w 3600
        else
            echo "Headnode in separate network. Attempt to contact $CENTRAL"
            ping $CENTRAL -w $PTIMEOUT
            if [[ "$?" == "0" ]]
            then
                echo "CENTRAL present"
                worker.pl http://$CENTRAL:$WORKERPORT 0099 ~/workerlog -w 3600
                sleep 5
            else
                echo "No CENTRAL or Headnode found"
                echo "Sleeping"
                sleep 10;
            fi
        fi
    done
}
worker_loop &
EOF'
}

check_keys ()
{
    [[ ! -f ~/.ssh/google_compute_engine      ]] && echo "Google private key missing" && return
    [[ ! -f ~/.ssh/google_compute_engine.pub  ]] && echo "Google public key missing"  && return
    echo "Google keys present in ~/.ssh"
}


stop_workers()
{
    echo "Stopping all instances"
    INSTANCES=$(gcutil --project=$GCE_PROJECTID listinstances | grep worker | awk '{print $2}')
    gcutil --project=$GCE_PROJECTID deleteinstance $INSTANCES --delete_boot_pd --force
}


stop_n_workers()
{
    COUNT=1
    [ ! -z "$1" ] && COUNT=$1
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
    cat <<EOF > swift.properties
site=cloud,local1
use.provider.staging=true
execution.retries=2

site.cloud {
   taskWalltime=04:00:00
   initialScore=10000
   filesystem=local
   jobmanager=coaster-persistent:local:local:http://$EXTERNAL_IP:$SERVICE_PORT
   workerManager=passive
   taskThrottle=800
   workdir=/home/$USER/work
}

site.local1 {
   jobmanager=local
   initialScore=10000
   filesystem=local
   workdir=/tmp/swiftwork
}
EOF


}

start_headnode()
{
    setup_firewall
    headnode_detail=$(gcutil --project=$GCE_PROJECTID listinstances | grep "headnode")
    if [ "$?" == "0" ]
    then
        echo "Headnode is present [$headnode_detail]"
        generate_swiftproperties
        return 0
    else
        echo "Headnode is not present, starting headnode ..."
    fi
    gcutil --project=$GCE_PROJECTID \
        addinstance headnode \
        --image=$HEADNODE_IMAGE \
        --zone=$GCE_ZONE \
        --auto_delete_boot_disk \
        --machine_type=$HEADNODE_MACHINE_TYPE \
        --metadata=startup-script:'#!/bin/bash
WORKERPORT="50005"
SERVICEPORT="50010"

#cd /usr/local/bin
#wget http://ci.uchicago.edu/~yadunandb/swift-0.95-package.tar.gz
#tar -xvzf swift-0.95-package.tar.gz
export JAVA=/usr/local/bin/jdk1.7.0_51/bin
export SWIFT=/usr/local/bin/swift-0.95/bin
export PATH=$JAVA:$SWIFT:$PATH

coaster_loop ()
{
    while :
    do
        coaster-service -p $SERVICEPORT -localport $WORKERPORT -nosec -passive &> /var/log/coaster-service.logs
        sleep 10;
    done
}

coaster_loop &
EOF'
    generate_swiftproperties
}


list_resources()
{
    gcutil --project=$GCE_PROJECTID listinstances | grep worker | awk '{print $2}'
}

dissolve()
{
    stop_headnode;
    stop_workers;
}

connect()
{
    NODE=$1
    [[ -z $1 ]] && NODE="headnode"
    gcutil --project=$GCE_PROJECTID ssh $NODE
}


