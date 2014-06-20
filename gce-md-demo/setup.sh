# ensure that this script is being sourced
if [ ${BASH_VERSINFO[0]} -gt 2 -a "${BASH_SOURCE[0]}" = "${0}" ] ; then
  echo ERROR: script ${BASH_SOURCE[0]} must be executed as: source ${BASH_SOURCE[0]}
  exit 1
fi

if [[ $HOSTNAME == headnode* ]]
then
    
    export JAVA=/usr/local/bin/jdk1.7.0_51/bin
    export SWIFT=/usr/local/bin/swift-0.95/bin
    export PATH=$JAVA:$SWIFT:$PATH
else # Running on local machine
    for p in 04 05 06
    do
        cp ../compute-engine/swift.properties part${p}/swift.properties
    done    
fi
echo Swift version is $(swift -version)

# Add applications to $PATH
TUTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATH=$TUTDIR/bin:$TUTDIR/app:$PATH

[[ -d "$HOME/.swift" ]] && mv $HOME/.swift $HOME/.swift_backup