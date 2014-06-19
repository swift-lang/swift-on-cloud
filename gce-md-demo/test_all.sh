#!/bin/bash

for test_case in $(echo part*)
do
    pushd .
    echo "****************TESTING $test_case   *******************"
    cd $test_case
    swift *.swift
    cleanup
    echo "********************************************************"
    popd

done