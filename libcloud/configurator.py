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

#configs = read_configs("./configs")
