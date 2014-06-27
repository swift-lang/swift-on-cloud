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

        #print "Credentials file = ", config['AWS_CREDENTIALS_FILE']
        cred_lines    =  open(config['AWS_CREDENTIALS_FILE']).readlines()
        cred_details  =  cred_lines[1].split(',')
        credentials   = { 'AWS_Username'   : cred_details[0],
                          'AWSAccessKeyId' : cred_details[1],
                          'AWSSecretKey'   : cred_details[2] }
        config.update(credentials)
    else:
        print "AWS_CREDENTIALS_FILE , Missing"

    return config


def aws_launch(conn, configs):
    instances = conn.get_all_instances()
    print instances
    conn.run_instances(configs['HEADNODE_IMAGE'],
                       key_name=configs['AWS_KEYPAIR_NAME'],
                       instance_type=configs['HEADNODE_MACHINE_TYPE'],
                       security_groups=[configs['SECURITY_GROUP']],
                       user_data="""#!/bin/bash
mkdir /usr/local/bin/DODODO
mkdir /hi
""" )
    instances = conn.get_all_instances()
    print instances


def list_reservations(conn, configs):
    reservations= conn.get_all_reservations()
    return reservations

# instance_ids should be a list of instance ids
def terminate_instances(conn, configs, instances):
    print "Terminating instances : ", instances
    conn.terminate_instances(instance_ids=instances)

def init():
    configs = read_configs("./configs")
    conn    = boto.ec2.connect_to_region(configs['AWS_REGION'],
                                         aws_access_key_id=configs['AWSAccessKeyId'],
                                         aws_secret_access_key=configs['AWSSecretKey'])
    return (conn, configs)


def list_resources(conn, configs):
    reservations = conn.get_all_reservations()
    print "     ID     |            EXTERNAL ADDRESS                      | STATUS "
    for reservation in reservations:
        for instance in reservation.instances:
            print instance.id, " | ", instance.public_dns_name, " | ", instance.state_code, " | ", instance.ip_address


def dissolve(conn, configs):
    reservations = conn.get_all_reservations()
    instance_ids = []
    for reservation in reservations:
        for instance in reservation.instances:
            instance_ids.append(instance.id)
    terminate_instances(conn, configs, instance_ids)


# The driving section
conn, configs = init()
pretty_configs(configs)
#aws_launch(conn, configs)
reservations = list_reservations(conn, configs)
dissolve(conn, configs)
list_resources(conn,configs)
'''
for reservation in reservations:
    instances  = reservation.instances
    print "Reservation : ",reservation
    print "Instances   : ",instances
    terminate_instance(conn, configs, instances)
'''
