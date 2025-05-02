#!/bin/bash

#
# Install SGX PSW
#


# Exit immediately if a command exits with a non-zero status
set -e

#
# Seems the PSW needs some SDK libraries
#
source /opt/intel/sgxsdk/environment

cd linux-sgx # make sure to be in the right directory here

# ----------------- Build SGX platform software -------------------
echo "[ Building SGX PSW ]"

# Build the PSW with or without debug info
if [ $debug_info -eq 1 ]
then 
#make psw_install_pkg DEBUG=1 -j`nproc`
make deb_psw_pkg DEBUG=1 -j`nproc`
else
#make psw_install_pkg -j`nproc`
make deb_psw_pkg -j`nproc`
fi

# Build local debian package repository
make deb_local_repo

#
# Debian local repo: linux/installer/deb/sgx_debian_local_repo | Ex. full path: /home/petman/projects/linux-sgx/linux/installer/deb/sgx_debian_local_repo
# Follow instructions in sgx readme to configure and install
#
echo "[ SGX PSW successfully built. Follow instructions in SGX readme to install PSW packages. ]"

#
# Example configurations:
# Ubuntu 20.04: sudo su -c "echo 'deb [trusted=yes arch=amd64] file:/home/petman/projects/linux-sgx/linux/installer/deb/sgx_debian_local_repo focal main' >> /etc/apt/sources.list"
# Ubuntu 22.04: sudo su -c "echo 'deb [trusted=yes arch=amd64] file:/home/petman/projects/linux-sgx/linux/installer/deb/sgx_debian_local_repo jammy main' >> /etc/apt/sources.list"
#
# After adding, do: sudo apt update
# Install the different PSW services as shown here: https://github.com/intel/linux-sgx?tab=readme-ov-file#install-the-intelr-sgx-psw-1
# Example (installs only packages for the launch service)
# sudo apt-get install libsgx-launch libsgx-urts
# 


if [ -e /opt/intel/sgxpsw/uninstall.sh ]
then
    sudo /opt/intel/sgxpsw/uninstall.sh
fi
#sudo ./sgx_linux_x64_psw_*.bin

