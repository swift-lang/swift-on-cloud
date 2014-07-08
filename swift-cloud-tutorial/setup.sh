# ensure that this script is being sourced
if [ ${BASH_VERSINFO[0]} -gt 2 -a "${BASH_SOURCE[0]}" = "${0}" ] ; then
  echo ERROR: script ${BASH_SOURCE[0]} must be executed as: source ${BASH_SOURCE[0]}
  exit 1
fi

# Setting scripts folder to the PATH env var.
TUTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ _$(which cleanup 2>/dev/null) != _$TUTDIR/bin/cleanup ]; then
  echo Adding $TUTDIR/bin:$TUTDIR/app: to front of PATH
  PATH=$TUTDIR/bin:$TUTDIR/app:$PATH
else
  echo Assuming $TUTDIR/bin:$TUTDIR/app: is already at front of PATH
fi

if [[ $HOSTNAME == headnode* ]]
then
    export JAVA=/usr/local/bin/jdk1.7.0_51/bin
    export SWIFT=/usr/local/bin/swift-0.95/bin
    export PATH=$JAVA:$SWIFT:$PATH
else # Running on local machine
    # Check if the variable PUBLIC_ADDRESS is set
    if [[ ! -z $PUBLIC_ADDRESS ]]
    then
        echo "PUBLIC_ADDRESS: Not set in current context"
        # Since PUBLIC_ADDRESS is not set, attempt to find PUBLIC_ADDRESS from cloud providers
        fname=$(ls -tr */PUBLIC_ADDRESS 2>/dev/null | tail -n 1)
        if [[ ! -z $fname ]]
        then # The last updated PUBLIC_ADDRESS file contains the PUBLIC_ADDRESS to be used
            PUBLIC_ADDRESS=$(cat $fname)
        else
            # TODO : Acquire service port from the cloud provider
            PUBLIC_ADDRESS=http://localhost:50010
        fi
    fi
    for p in 04 05 06
    do
        sed -i "s/http://localhost:50010/$PUBLIC_ADDRESS" part${p}/swift.properties
        #cp ../compute-engine/swift.properties part${p}/swift.properties
    done
fi

which swift &> /dev/null
if [[ "$?" !=  "0" ]]
then
    echo "WARNING: Swift not found in PATH"
else
    # Swift is in PATH
    # Check version
    version=$(swift -version)
    if [[ ! $version == *"Swift 0.95"* ]]
    then
        echo "WARNING: Please check the swift version, tutorial tested only on Swift 0.95 "
    fi
    echo "Swift version is $version"
fi
return

