# Welcome to Oreka, an open media capture and retrieval platform

> - Copyright (C) 2005, Orecx LLC: http://www.orecx.com
> - Modified and Distributed by: InterActiveTel LLC: http://interactivetel.com
> - Forked from: https://github.com/OrecX/Oreka


## How to build orkaudio binaries and create a release package

This directory contains the instructions, dependencies and scripts we use to build ***OrkAudio*** from source and create a release package. Here is a brief description of what you should expect to see:

- ***conf***: Our configuration files for ***OrkAudio***
- ***deps***: Binary and source dependencies required to build ***OrkAudio*** from source
- ***docs***: User, Administrator and Developer documentation
- ***scripts***: Helper scripts to pull changes from upstream, install and build release packages
- ***src***: Source code for our additions to ***OrkAudio***

## Build orkaudio from source
In order to build ***OrkAudio*** from source we will need to install some dependencies. You will need to find the packages needed by every distribution. Here is a list of dependencies needed:

`apr pcap boost xerces-c libsndfile ogg speex gsm opus silk log4cxx openssl`


### Install instructions for CentOS 6: 
Either use the install script or follow the manual instructions:


#### Using the script:
```bash
# Syntax: scripts/centos6/install.sh [install_prefix]

# Ej. Install into the system using /usr as prefix (default)
scripts/centos/install.sh

# Ej. Install to a temporal location so we can build a package later
scripts/centos/install.sh /usr/src/install_root
```

#### Manual install
1. Update the system and install a newer version of the toolchain
   ```bash
    sudo yum update -y
    sudo yum install -y wget doxygen libtool rpmdevtools epel-release centos-release-scl || abort
    sudo yum install -y devtoolset-7 || abort
   ```
2. Install the binary dependencies
    ```bash
    sudo yum install -y apr-devel apr-util-devel libpcap-devel boost-devel xerces-c-devel \
                        libsndfile-devel speex-devel libogg-devel openssl-devel
    ```
3. Install ***log4cxx***, this package is not available on ***CentOS 6***, we will use a rpm built from ***CentOS 7*** source rpm.
    ```bash
    # In case we needed to build the packages again from the source rpm do the following
    # wget -c http://vault.centos.org/7.5.1804/os/Source/SPackages/log4cxx-0.10.0-16.el7.src.rpm -O /usr/src/log4cxx-0.10.0-16.el7.src.rpm
    # rpmbuild --rebuild /usr/src/log4cxx-0.10.0-16.el7.src.rpm
    # yum install -y ~/rpmbuild/RPMS/x86_64/log4cxx-0.10.0-16.el6.x86_64.rpm \
    #                ~/rpmbuild/RPMS/x86_64/log4cxx-devel-0.10.0-16.el6.x86_64.rpm
    sudo yum install -y deps/centos6/log4cxx-0.10.0-16.el6.x86_64.rpm \
                        deps/centos6/log4cxx-devel-0.10.0-16.el6.x86_64.rpm
    ```

4. Enable the use of the newer toolchain
    ```bash 
    # using scl: 
    #  for bash: scl enable devtoolset-7 bash 
    #  for zsh: scl enable devtoolset-7 zsh
    #  for any: source /opt/rh/devtoolset-7/enable
    source /opt/rh/devtoolset-7/enable
    ```
 
 1. Build and install the Opus codec
    ```bash
    tar -C /usr/src -xf dependencies/src/opus-1.2.1.tar.gz
    pushd /usr/src/opus-1.2.1 &> /dev/null
    ./configure --prefix=/opt/opus/
    make -j CFLAGS="-fPIC -msse4.1"
    sudo make install
    sudo ln -sf /opt/opus/lib/libopus.a /opt/opus/lib/libopusstatic.a
    popd &> /dev/null
    ```
5. Build and install the silk codec
    ```bash
    tar -C /opt/ -xf dependencies/src/silk.tgz
    pushd /opt/silk/SILKCodec/SILK_SDK_SRC_FIX/ &> /dev/null
    sudo make clean
    sudo make -j lib
    popd &> /dev/null
    ```
6. Build and install orkbasecxx
    ```bash
    pushd ../orkbasecxx &> /dev/null
    autoreconf -i
    ./configure CXX=g++ CPPFLAGS=-DXERCES_3
    make -j
    sudo make install
    popd &> /dev/null
    ```
7. Build and install orkaudio
    ```bash
    pushd ../orkaudio &> /dev/null
    autoreconf -i
    ./configure CXX=g++ CPPFLAGS=-DXERCES_3
    make -j
    sudo make install
    popd &> /dev/null
    ```
8. Install G729 codec
    ```bash
    tar -C $/usr/src -xf ./dependencies/src/bcg729-1.0.0.tar.gz
    pushd $/usr/src/bcg729-1.0.0 &> /dev/null
    ./configure --prefix=/usr
    make -j
    make install
    popd &> /dev/null
    ```

## References
> Opus Codec: http://opus-codec.org/ 
> 
>SILK Codec: https://github.com/gaozehua/SILKCodec

