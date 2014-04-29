#!/bin/bash

LOG="./setup.log"
VERBOSE="True"

log ()
{
    if [[ "$VERBOSE" == "True" ]]
    then
        echo $* | tee $LOG
    else
        echo $* >> $LOG
    fi
}

install_gce_client()
{
    which pip &> LOG
    if [[ "$?" == "0" ]]
    then
        pip install --upgrade google-api-python-client
        if [[ "$?" == "0" ]]
        then
            log "pip install client success"
            return
        fi
    fi
    which easy_install
    if [[ "$?" == "0" ]]
    then
        easy_install --upgrade google-api-python-client
        if [[ "$?" == "0" ]]
        then
            log "easy_install client success"
            return
        fi
    fi
    log "Installing python-client failed"
}

install_gcloud_sdk()
{
    wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.zip
    unzip google-cloud-sdk.zip
    # Default answers to the install script
    # n(o) to collection of user data
    # 4 to select minimal installation
    # Y to update bashrc/profile
    # Y to add bash completion support
    ./google-cloud-sdk/install.sh  <<EOF
n
4

Y
Y

EOF
}

setup_GCE ()
{

    # Installation
    which gcloud && which gcutil
    if [[ "$?" == "0" ]]
    then
        log "SETUP: gcloud and gcutil already installed"
    else
        log "SETUP: gcloud / gcutil missing. Installing"
        #install_gce_client;
        install_gcloud_sdk | tee $LOG;
    fi

    # Authentication
    gcloud auth list | grep "No credentialed accounts."
    if [[ "$?" == "0" ]]
    then
        log "SETUP: Attempting gcloud login"
        log "SETUP: ****************** ATTENTION **********************"
        log "         One-time authentication attempt with google "
        log "Please copy the link which is generated below and copy to a"
        log "browser to authenticate. Once authenticated, copy the verification key "
        log "from the website to the commandline to complete the process"
        log " "
        gcloud auth login --no-launch-browser

        # Check if auth success
        gcloud auth list | grep "(active)"
        if [[ "$?" == "0" ]]
        then
            log "SETUP: Authentication success"
        else
            log "SETUP: Authentication failed!"
            return -1
        fi
    else
        log "SETUP: Authenticated with google"
    fi

    # Setup project
    [[ -z "$GCE_PROJECT" ]] && echo "SETUP: GCE_PROJECT not set, exiting" && return
    #gcloud config set project $GCE_PROJECT
    
    
    # Create a firewall rule to allow ports used by swift
    gcutil addfirewall --network=default swift-ports '--allowed=tcp:50000-60000,udp:50000-60000' --allowed_ip_sources='0.0.0.0/0'
}

# ensure that this script is being sourced
if [ ${BASH_VERSINFO[0]} -gt 2 -a "${BASH_SOURCE[0]}" = "${0}" ] ; then
  log ERROR: script ${BASH_SOURCE[0]} must be executed as: source ${BASH_SOURCE[0]}
  exit 1
fi

rm -rf $LOG &> /dev/null
log "Running setup on system $(uname -a)"

# Load the configs file
source configs
log "Project name : $GCE_PROJECT"
log "Project id   : $GCE_PROJECTID"
log "GCE_Workers  : $GCE_WORKERS"
setup_GCE | tee $LOG;


