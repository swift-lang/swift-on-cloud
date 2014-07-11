#!/bin/bash

for i in $(seq 1 1 5)
do
    pushd .
    echo "============================TESTING part0$i==========================="
    cd part0$i
    swift p$i.swift
    if [[ $? == 0 ]]
    then
        echo "Cleaning up!"
        cleanup
    fi
    echo -e "\n\n"
    popd
done
