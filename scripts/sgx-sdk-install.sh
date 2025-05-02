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


# Install required tools to build the Intel SGX SDK

if [ $OS_REL = "22.04" ];
then 
# SGX SDK requirements
sudo apt-get install build-essential ocaml ocamlbuild automake autoconf libtool wget python-is-python3 libssl-dev git cmake perl -y
# SGX PSW requirements
sudo apt-get install libssl-dev libcurl4-openssl-dev protobuf-compiler libprotobuf-dev debhelper cmake reprepro unzip -y


elif [ $OS_REL = "18.04" ];
then 
# SGX SDK requirements
sudo apt-get install build-essential ocaml ocamlbuild automake autoconf libtool wget python libssl-dev git cmake perl -y
# SGX PSW requirements
sudo apt-get install libssl-dev libcurl4-openssl-dev protobuf-compiler libprotobuf-dev debhelper cmake reprepro unzip -y


elif [ $OS_REL = "20.04" ];
then 
# SGX SDK requirements
sudo apt-get install build-essential ocaml ocamlbuild automake autoconf libtool wget python-is-python3 libssl-dev git cmake perl -y
# SGX PSW requirements
sudo apt-get install libssl-dev libcurl4-openssl-dev protobuf-compiler libprotobuf-dev debhelper cmake reprepro unzip -y

fi

# Install additional requirements for 16.04, 18.04, 20.04, 22.04, 23.10
sudo apt-get install libssl-dev libcurl4-openssl-dev protobuf-compiler libprotobuf-dev debhelper cmake reprepro unzip -y 
sudo apt-get install pkgconf libboost-dev libboost-system-dev libboost-thread-dev lsb-release libsystemd0 -y


#git submodule init
#git submodule update

#OS_ID=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
#OS_REL=$(lsb_release -sr)
#OS_STR=$OS_ID$OS_REL

# ----------------------------------------------------------------------

# Driver install commands

# ----------------------------------------------------------------------
# Download the source code and prepare the submodules and prebuilt binaries:
echo "[ Building SGX SDK ]"
cd $script_path
git clone https://github.com/intel/linux-sgx.git
#git clone https://gitlab.com/Yuhala/sgx-sdk-modified.git

#sdk with modified memcpy
#git clone https://gitlab.com/michaelpaper/linux-sgx.git


#cd sgx-sdk-modified/linux-sgx
cd linux-sgx
git fetch --all --tags
git checkout tags/$sgx_sdk_version

#
# Prepare submodules and prebuilt binaries
# make preparation would trigger the script download_prebuilt.sh to download the prebuilt binaries. 
# You may need to set an https proxy for the wget tool used by the script (such as export https_proxy=http://test-proxy:test-port
#
make preparation

#
# Copy mitigation tools for current OS 
# Note: Mitigation tools are only provided for the operating systems whose binutils lack mitigation options support. 
# If your operating system is not listed in the external/toolset/{current_distr} directory, you can skip this step. 
# Otherwise, even if you previously copied the mitigation tools to /usr/local/bin, performing the above action is still necessary. 
# This ensures that the latest mitigation tools are used during the subsequent build process.
#

echo "[ Copying mitigation tools ]"
# sudo cp external/toolset/ubuntu$OS_REL/* /usr/local/bin

#
# Build the sdk with or without debug info
# USE_OPT_LIBS=0 build SDK using SGXSSL and open sourced String/Math
# See original readme for more options
#

if [ $debug_info -eq 1 ];
then 
make sdk_install_pkg USE_OPT_LIBS=0 DEBUG=1 -j`nproc`
else
make sdk_install_pkg USE_OPT_LIBS=0 -j`nproc`
fi


echo "[ Installing SGX SDK system-wide ]"
cd linux/installer/bin/
sudo ./sgx_linux_x64_sdk_*.bin << EOF
no
/opt/intel
EOF
cd ../../../

echo "SGX SDK succesfully installed!"

#
# Seems the PSW needs some SDK libraries
#
source /opt/intel/sgxsdk/environment

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

