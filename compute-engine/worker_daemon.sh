#!/bin/bash

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

worker_loop &> ~/worker_daemon.log &