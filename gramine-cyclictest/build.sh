#!/bin/bash

# clean and build
make clean
make SGX=1

ARG_1=${1}

# run gramine cpc
# TODO: how to handle main arguments in gramine?

#sudo gramine-sgx cpc "$ARG_1"

sudo gramine-sgx cyclictest > gramine_idle.ct

