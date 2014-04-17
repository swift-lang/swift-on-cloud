#!/bin/bash


WORKERS=20
#PROJECT_NAME="swift-ninja"
WORKER_MACHINE_TYPE="f1-micro"
WORKER_ZONE="us-central1-b"
#WORKER_IMAGE="projects/debian-cloud/global/images/debian-7-wheezy-v20140408"
WORKER_IMAGE="swift-worker-image"
LOG=Setup_$$.log

start_worker ()
{
    ID=$1;
    if [[ -z $ID ]]
    then
        echo "No ID provided to name worker instance"
        return
    fi
    gcutil addinstance swift-worker-$ID \
        --image=$WORKER_IMAGE \
        --zone=$WORKER_ZONE \
        --machine_type=$WORKER_MACHINE_TYPE \
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
sudo apt-get install perl
worker_loop &
EOF'
    #ssh -i ~/.ssh/google_compute_engine
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
    INSTANCES=$(gcutil listinstances | grep worker | awk '{print $2}')
    gcutil deleteinstance $INSTANCES
}

# Start N workers in parallel ?
start_n_workers ()
{
    COUNT=$1
    for i in $(seq 1 1 $COUNT)
    do
        start_worker $i &> $LOG &
    done
    wait
    gcutil listinstances
    echo "Updating WORKER_HOSTS"
    EXTERNAL_IPS=$(gcutil listinstances | grep worker | awk '{print $10}')
    WORKER_NAMES=$(gcutil listinstances | grep worker | awk '{print $2}')
}

start_n_more ()
{
    ACTIVE=$(gcutil listinstances | grep worker | wc -l)
    MORE=$1
    for i in $(seq $(($ACTIVE+1)) 1 $(($ACTIVE+$MORE)) )
    do
        echo "Starting worker $i"
        start_worker $i &> $LOG &
    done
    wait
    gcutil listinstances
    echo "Updating WORKER_HOSTS"
    EXTERNAL_IPS=$(gcutil listinstances | grep worker | awk '{print $10}')
    WORKER_NAMES=$(gcutil listinstances | grep worker | awk '{print $2}')
}


start_worker 9
#check_keys;
#stop_workers;
#start_worker 3
#start_n_more 5

#start_n_more 3
#stop_workers;
#exit 0;
# gcutil addfirewall swift '--allowed=tcp:ssh,tcp:50000-55000'

