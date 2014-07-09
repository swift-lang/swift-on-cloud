#!/bin/bash

WORKERPOR='50005'
SERVICEPORT='50010'

cd /usr/local/bin
wget http://swift-lang.org/packages/swift-0.95-RC6.tar.gz
wget http://users.rcc.uchicago.edu/~yadunand/jdk-7u51-linux-x64.tar.gz

tar -xvzf swift-0.95-RC6.tar.gz
tar -xvzf jdk-7u51-linux-x64.tar.gz

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
