#!/bin/bash

#
# Script to install the Intel SGX driver, SDK, and PSW on Ubuntu based systems.
# This script is based on the installation instructions from Intel:
# SGX driver installation: https://github.com/intel/linux-sgx-driver/blob/main/README.md
# and 
# SGX SDK + PSW installation: https://github.com/intel/linux-sgx/blob/main/README.md
# Tested on Ubuntu: 20.04 LTS and  22.04.4 LTS
# 
# 


# Exit immediately if a command exits with a non-zero status
set -e


# Ubuntu release
OS_REL=$(lsb_release -sr)
# Current working directory
script_path=$(pwd)
# SGX version tag
sgx_sdk_version="sgx_2.24"
# SGX driver version tag
sgx_driver_version="sgx_driver_2.14" 
# Debug info
debug_info=1

# ----------------------------------------------------------------------
# Stop aesmd service
# sudo service aesmd stop
# Install SGX Driver

git clone https://github.com/intel/linux-sgx-driver.git
cd linux-sgx-driver
git fetch --all --tags
git checkout tags/$sgx_driver_version

# 
# To build the driver, the version of installed kernel headers must match the active kernel version on the system
# Install matching kernel headers:
#
sudo apt-get -yqq install linux-headers-$(uname -r)
make
sudo mkdir -p "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
sudo cp isgx.ko "/lib/modules/"`uname -r`"/kernel/drivers/intel/sgx"
sudo sh -c "cat /etc/modules | grep -Fxq isgx || echo isgx >> /etc/modules"
sudo /sbin/depmod
sudo /sbin/modprobe isgx

echo "SGX driver succesfully installed"