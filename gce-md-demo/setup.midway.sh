# Load modules
#module unload swift
#module load swift/0.95-RC1

module load ant

PATH=/home/wilde/swift/src/trunk/cog/modules/swift/dist/swift-svn/bin:$PATH

echo Swift version is $(swift -version)

# Add applications to $PATH
TUTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PATH=$TUTDIR/bin:$TUTDIR/app:$PATH
