#!/usr/bin/env python

import os
import configurator

from libcloud.compute.types import Provider
from libcloud.compute.providers import get_driver
from libcloud.compute.base import NodeSize, NodeImage

def aws_test():
    print "hello"

def list_resources(ec2_driver):
    resources = ec2_driver.list_nodes()
    for resource in resources:
        print resource.name, " | ", resource.state, " | ", resource.public_ips
    return resources

def connect (node_name):
    #ssh -l "ec2-user" -i ami-d5b0cee5 ec2-54-187-207-20.us-west-2.compute.amazonaws.com
    print "ERROR: Feature not available"

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

def start_node(driver, configs):
    userdata   = "\n".join(open("headnode_userdata").readlines())

    print userdata
    size       = NodeSize(id=configs['HEADNODE_MACHINE_TYPE'], name='headnode',
                          ram=None, disk=None, bandwidth=None, price=None, driver=driver)
    image      = NodeImage(id=configs['HEADNODE_IMAGE'], name=None, driver=driver)
    node       = driver.create_node(name='headnode',
                                    image=image,
                                    size=size,
                                    ex_keyname=configs['AWS_KEYPAIR_NAME'],
                                    ex_securitygroup=configs['SECURITY_GROUP'],
                                    ex_userdata=userdata )

def dissolve(driver, configs):
    print "dissolve"

def init():
    configs    = configurator.read_configs('configs')
    configurator.pretty_configs(configs)
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

def delete_node():
    configs,driver = init()
    nodes          = driver.list_nodes()
    for node in nodes:
        print "Deleting node : ", node.name
        driver.destroy_node(node)

create_node()
#foo()

#init()
