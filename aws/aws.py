#!/usr/bin/env python

import os
import configurator
import sys
import random

from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver
from libcloud.compute.base import NodeSize, NodeImage
from libcloud.compute.types import NodeState


NODESTATES = { NodeState.RUNNING    : "RUNNING",
               NodeState.REBOOTING  : "REBOOTING",
               NodeState.TERMINATED : "TERMINATED",
               NodeState.STOPPED    : "STOPPED",
               NodeState.PENDING    : "PENDING",
               NodeState.UNKNOWN    : "UNKNOWN" }

def list_resources(ec2_driver):

    resources = ec2_driver.list_nodes()
    if not resources:
        print "No active resources"
    else:
        print '-'*51
        print '{0:20} | {1:10} | {2:15}'.format("NAME", "STATUS", "EXTERNAL_IP")
        print '-'*51
        for resource in resources:
            if resource.public_ips:
                #print resource.name, " | ", NODESTATES[resource.state] , " | ", resource.public_ips[0]
                print '{0:20} | {1:10} | {2:15}'.format(resource.name, NODESTATES[resource.state], resource.public_ips[0])
                print '-'*51

    return resources


def get_public_ip(ec2_driver, name):
    resources = ec2_driver.list_nodes()
    if not resources:
        print "No active resources"
    for resource in resources:
        if resource.name == name and resource.public_ips:
            print resource.public_ips[0]
            return resource

    print "Could not find a resource with the id ", name
    return -1

def create_security_group(ec2_driver):
    group_name = "swift_security_group1"
    current    = ec2_driver.ex_list_security_groups()
    if group_name in current:
        print group_name, "Is already present"
    else:
        print group_name, "Creating new security group"
        res = ec2_driver.ex_create_security_group(name=group_name,description="Open all ports")
        print res

    if not ec2_driver.ex_authorize_security_group(group_name, 0, 65000, '0.0.0.0/0'):
        print "Authorizing ports for security group failed"
    if not ec2_driver.ex_authorize_security_group(group_name, 0, 65000, '0.0.0.0/0', protocol='udp'):
        print "Authorizing ports for security group failed"
    print res

def start_headnode(driver, configs):
    userdata   = configurator.getstring("headnode")

    size       = NodeSize(id=configs['HEADNODE_MACHINE_TYPE'], name='headnode',
                          ram=None, disk=None, bandwidth=None, price=None, driver=driver)
    image      = NodeImage(id=configs['HEADNODE_IMAGE'], name=None, driver=driver)
    node       = driver.create_node(name='headnode',
                                    image=image,
                                    size=size,
                                    ex_keyname=configs['AWS_KEYPAIR_NAME'],
                                    ex_securitygroup=configs['SECURITY_GROUP'],
                                    ex_userdata=userdata )
    if node.public_ips:
        print '-'*51
        print '{0:20} | {1:10} | {2:15}'.format(node.name, NODESTATES[node.state], node.public_ips[0])
        print '-'*51


def start_worker(driver, configs, worker_names):
    nodes      = driver.list_nodes()
    headnode   = False
    for node in nodes:
        if node.name == "headnode" and node.state == NodeState.RUNNING:
            headnode = node
    if not headnode :
        print "WARNING : No active headnode found"
        return -1

    # Setup userdata
    userdata   = configurator.getstring("headnode")
    userdata   = userdata.replace("SET_HEADNODE_IP", headnode.public_ips[0])

    print userdata

    list_nodes = []
    for worker_name in worker_names:
        size       = NodeSize(id=configs['WORKER_MACHINE_TYPE'], name=worker_name,
                              ram=None, disk=None, bandwidth=None, price=None, driver=driver)
        image      = NodeImage(id=configs['WORKER_IMAGE'], name=None, driver=driver)
        node       = driver.create_node(name=worker_name,
                                        image=image,
                                        size=size,
                                        ex_keyname=configs['AWS_KEYPAIR_NAME'],
                                        ex_securitygroup=configs['SECURITY_GROUP'],
                                        ex_userdata=userdata )
        list_nodes.append(node)
    print list_nodes

def dissolve(driver, configs):
    print "dissolve"

def init():
    configs    = configurator.read_configs('configs')
    #configurator.pretty_configs(configs)
    driver     = get_driver(Provider.EC2_US_WEST_OREGON) # was EC2
    ec2_driver = driver(configs['AWSAccessKeyId'], configs['AWSSecretKey'])
    return configs,ec2_driver

def create_node():
    configs,driver = init()
    resources  = list_resources(driver)
    print resources
    #create_security_group(ec2_driver)
    start_node(driver,configs)
    resources  = list_resources(driver)
    print resources

def terminate_all_nodes():
    configs,driver = init()
    nodes          = driver.list_nodes()
    for node in nodes:
        print "Deleting node : ", node.name
        driver.destroy_node(node)

def terminate_node(driver, node_name):
    nodes          = driver.list_nodes()
    for node in nodes:
        if node.name == node_name and node.state == NodeState.RUNNING :
            print "Deleting node : ", node.name
            code = driver.destroy_node(node)
            return code
    print "ERROR: Could not find node ", node_name
    return 1


def no_func(string):
    print "Sorry no such function defined", string


def help():
    help_string = """ Usage for aws.py : python aws.py [<option> <arguments...>]
    start_worker <worker_id> : Starts worker with name set to worker_id, returns a unique id
    stop_node <id>           : Terminates the node which matches the id with its name or unique id
    start_headnode           : Starts the headnode, to which workers connect to
    stop_headnode            : Terminates the headnode
    dissolve                 : Terminates all active resources
    list_resources           : List all resources
    list_resource <id/name>  : List the public ip and state of the resource
"""
    print help_string
    exit(1)

# Main driver section
configs, driver = init()
args = sys.argv[1:]
#print "All args : ",str(args)

if len(args) < 1:
    help()

if   args[0] == "start_worker":
    worker_name = "swift-worker-" + str(random.randint(1,999))
    if len(args) ==  2 :
        worker_name = args[1]
    start_worker(driver,configs,[worker_name])

elif args[0] == "check_keys":
    check_keys(driver,configs)

elif args[0] == "start_headnode":
    start_headnode(driver,configs)

elif args[0] == "stop_headnode":
    terminate_node(driver,"headnode")

elif args[0] == "stop_node":
    if len(args) != 2 :
        help
    terminate_node(driver,args[1])

elif args[0] == "dissolve":
    terminate_all_nodes()

elif args[0] == "list_resources":
    list_resources(driver)

elif args[0] == "list_resource":
    if len(args) !=  2 :
        help
    get_public_ip(driver, args[1])

else:
    print "ERROR: Option ", args[0], " not recognized"
    help()


#create_node()
#foo()

#init()
