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
    # Y to add baupsh completion support
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

}


# Check if we are running bash
if [ ! -n "$BASH_VERSION" ]
then
 log WARNING: please source the setup.sh script from bash.
 log WARNING: Setup is not tested outside bash. Unexpected behavior is likely.
 
# ensure that this script is being sourced
elif [ ${BASH_VERSINFO[0]} -gt 2 -a "${BASH_SOURCE[0]}" = "${0}" ]
then
  log ERROR: script ${BASH_SOURCE[0]} must be executed as: source ${BASH_SOURCE[0]}
  exit 1
fi

rm -rf $LOG &> /dev/null
log "Running setup on system $(uname -a)"

# Check for essential components
which gcloud &> /dev/null
[[ "$?" != "0" ]] && echo "ERROR: gcloud could not be found in system PATH" && return -1

which gcutil &> /dev/null
[[ "$?" != "0" ]] && echo "ERROR: gcutil could not be found in system PATH" && return -1

# Load the configs file
source configs
echo "Attempting updates"
gcloud components update

log "Project name  : $GCE_PROJECT"
log "Project id    : $GCE_PROJECTID"
log "GCE_Workers   : $GCE_WORKER_COUNT"
source commands.sh

check_project
start_headnode
start_n_workers $GCE_WORKER_COUNT



