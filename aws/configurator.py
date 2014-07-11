#!/usr/bin/env python

import os
import pprint
import boto.ec2

def _read_conf(config_file):
    cfile = open(config_file, 'r').read()
    config = {}
    for line in cfile.split('\n'):

        # Checking if empty line or comment
        if line.startswith('#') or not line :
            continue

        temp = line.split('=')
        config[temp[0]] = temp[1].strip('\r')
    return config

def pretty_configs(configs):
    printer = pprint.PrettyPrinter(indent=4)
    printer.pprint(configs)


def read_configs(config_file):
    config = _read_conf(config_file)

    if 'AWS_CREDENTIALS_FILE' in config :
        config['AWS_CREDENTIALS_FILE'] =  os.path.expanduser(config['AWS_CREDENTIALS_FILE'])
        config['AWS_CREDENTIALS_FILE'] =  os.path.expandvars(config['AWS_CREDENTIALS_FILE'])

        cred_lines    =  open(config['AWS_CREDENTIALS_FILE']).readlines()
        cred_details  =  cred_lines[1].split(',')
        credentials   = { 'AWS_Username'   : cred_details[0],
                          'AWSAccessKeyId' : cred_details[1],
                          'AWSSecretKey'   : cred_details[2] }
        config.update(credentials)
    else:
        print "AWS_CREDENTIALS_FILE , Missing"
        print "ERROR: Cannot proceed without access to AWS_CREDENTIALS_FILE"
        exit(-1)

    if 'AWS_KEYPAIR_FILE' in config:
        config['AWS_KEYPAIR_FILE'] = os.path.expanduser(config['AWS_KEYPAIR_FILE'])
        config['AWS_KEYPAIR_FILE'] = os.path.expandvars(config['AWS_KEYPAIR_FILE'])
    return config

#configs = read_configs("./configs")
#pretty_configs(configs)

#!/usr/bin/env python

HEADNODE_USERDATA='''#!/bin/bash
WORKERPORT="50005"; SERVICEPORT="50010"
export JAVA=/usr/local/bin/jdk1.7.0_51/bin
export SWIFT=/usr/local/bin/swift-0.95-RC6/bin
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
'''

WORKER_USERDATA='''#!/bin/bash
HEADNODE=SET_HEADNODE_IP
WORKERPORT="50005"
#Ping timeout
PTIMEOUT=4
export JAVA=/usr/local/bin/jdk1.7.0_51/bin
export SWIFT=/usr/local/bin/swift-0.95-RC6/bin
export PATH=$JAVA:$SWIFT:$PATH
worker_loop ()
{
    while :
    do
        echo "Pinging HEADNODE on $HEADNODE"
        worker.pl http://$HEADNODE:$WORKERPORT 0099 ~/workerlog -w 3600
        sleep 5
    done
}
worker_loop &
'''

def getstring(target):
    if target == "headnode":
        return HEADNODE_USERDATA
    elif target == "worker":
        return WORKER_USERDATA
    else:
        return -1

