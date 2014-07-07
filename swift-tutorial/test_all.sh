#!/bin/bash



SITES=('beagle' 'beagle-remote')
for i in $(seq 4 1 6)
do
    pushd .
    echo "============================TESTING part0$i==========================="
    cd part0$i

    for SITE in ${SITES[*]}
    do
        echo "Running on SITE : $SITE"
        swift p$i.swift -site=$SITE
        if [[ $? == 0 ]]
        then
            echo "Cleaning up!"
            cleanup
        fi
    done
    echo -e "\n\n"
    popd
done
