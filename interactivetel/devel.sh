#!/usr/bin/env bash
set -eE

cd "$(dirname "$0")"

. lib.sh


ORKAUDIO_DIR=$(readlink -f ../orkaudio)

BUILD_DIR=$(mktemp -d -t orkaudio-deps.XXX)
trap 'rm -rf "${BUILD_DIR}"' EXIT

OPUS_LIB=opus-1.3.1
SILK_LIB=silk
G729_LIB=bcg729-1.1.1


usage() {
    info "::: Description:"
    info ":::   Setup OrkAudio/OrkBaseCXX for development with Autotools"
    info ":::"
    info "::: Supported systems:"
    info ":::   Debian, Ubuntu, CentOS and RedHat."
    info ":::"
    info "::: Usage:"
    info ":::   devel.sh [ -h | --help | clean | setup ]"
    info ":::"
    info ":::   -h | --help: Show this message"
    info ":::   clean: clean OrkAudio/OrkBaseCXX source tree and dependencies"
    info ":::   setup: Installs OrkAudio/OrkBaseCXX binary and source dependencies, also, preconfigure the projects"
    info ":::"
}


install_binary_deps() {
    header "Installing binary dependencies"

    # install base dependencies
    test -z "BASE_DIST" && system-detect
    if [[ "$BASE_DIST" = "redhat" ]]; then
        # fix centos 6 repositories (EOL)
        fix-centos6-repos

        # install custom repositories
        install-custom-repos

        # update the system
        sudo yum -y update

        # install development tools
        sudo yum install -y git curl wget mc htop libtool rpmdevtools devtoolset-9 cmake3 sngrep \
            net-tools bind-utils gawk


        # orkaudio dependencies, log4cxx and log4cxx-devel: v0.10.0
        sudo yum -y install apr-devel libpcap-devel boost-devel xerces-c-devel libsndfile-devel \
            speex-devel libogg-devel openssl-devel log4cxx log4cxx-devel gawk
    else
        # update the system
        sudo apt-get -y update
        sudo apt-get -y upgrade

        # install development tools
        sudo apt-get -y install git curl wget mc htop libtool cmake sngrep net-tools dnsutils build-essential

        # orkaudio dependencies, log4cxx and log4cxx-devel: v0.10.0
        sudo apt-get -y install libapr1-dev libpcap-dev libboost-all-dev libxerces-c-dev libsndfile1-dev \
            libspeex-dev libopus-dev  libssl-dev liblog4cxx-dev
    fi

    printf "\n\n"
}


install_source_deps() {
	# create install dir for deps (silk and opus)
	sudo mkdir -p /opt/{silk,opus}
	sudo chown -R $USER /opt

    # build opus codec lib
    header "Building Opus lib"
    tar -C "$BUILD_DIR" -xvpf libs/opus-1.3.1.tar.gz

    pushd "$BUILD_DIR/opus-1.3.1" &> /dev/null
    ./configure --prefix=/opt/opus --enable-shared=no --with-pic
    make clean
    make -j
    make install
    ln -sf /opt/opus/lib/libopus.a /opt/opus/lib/libopusstatic.a
    popd &> /dev/null

    printf "\n\n"

    # build silk codec
    header "Building Silk lib"
    tar -C /opt -xvpf libs/silk.tgz

    pushd /opt/silk/SILKCodec/SILK_SDK_SRC_FIX &> /dev/null
    make clean
    CFLAGS="-fPIC" make -j lib
    popd &> /dev/null

    printf "\n\n"

    # build G729 codec
    header "Building G729 lib"
    tar -C "$BUILD_DIR" -xvpf libs/bcg729-1.1.1.tar.gz

    pushd "$BUILD_DIR/bcg729-1.1.1" &> /dev/null
    if [[ "$BASE_DIST" == "redhat" ]]; then
        cmake3 . -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_SHARED=YES -DENABLE_STATIC=NO -DCMAKE_SKIP_INSTALL_RPATH=ON
    else
        cmake . -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_SHARED=YES -DENABLE_STATIC=NO -DCMAKE_SKIP_INSTALL_RPATH=ON
    fi
    make clean
    make -j
    sudo make install
    popd &> /dev/null

    sudo ldconfig

    printf "\n\n"
}


clean() {
	header "Cleaning OrkAudio/OrkBaseCXX build tree and dependencies"
    rm -rf "$BUILD_DIR" || :
    for DIR in orkaudio orkbasecxx; do
        pushd "../$DIR" &> /dev/null
        test -f Makefile && make distclean
        popd &> /dev/null
    done

    sudo rm -rf /var/log/orkaudio /etc/orkaudio
    sudo rm -rf /opt/{silk,opus}
    sudo rm -rf /usr/include/bcg729 /usr/lib/pkgconfig/libbcg729.pc /usr/lib/libbcg729.* /usr/lib64/libbcg729.*
    sudo rm -rf /usr/lib64/libbcg729.* /usr/lib64/pkgconfig/libbcg729.pc /usr/lib/x86_64-linux-gnu/libbcg729.* /usr/lib/x86_64-linux-gnu/pkgconfig/libbcg729.pc
    sudo rm -rf /usr/share/Bcg729
}


setup() {
    system-detect
    if [[ "$OS" != "linux" ]]; then
      abort "Unsupported operating system: $OS, we only support linux"
    fi
    
    install_binary_deps
    if [[ "$BASE_DIST" = "redhat" ]]; then
        source /opt/rh/devtoolset-9/enable
    fi

    # install orkaudio
    install_source_deps

    # configure orkbasecxx
    header "::: Preconfiguring OrkBaseCXX"

    pushd ../orkbasecxx &> /dev/null
    autoreconf  -f -i
    popd &> /dev/null

    printf "\n\n"

    # configure orkaudio
    header "Preconfiguring OrkAudio"
    pushd ../orkaudio &> /dev/null
    autoreconf  -f -i
    popd &> /dev/null

    printf "\n\n"

    header "::: Generating development configuration files"

    # log files
    sudo mkdir -p /var/log/orkaudio
    sudo chown -R jmrbcu /var/log/orkaudio

    # config files
    sudo mkdir -p /etc/orkaudio
    sudo chown -R jmrbcu /etc/orkaudio
    cp -f conf/* /etc/orkaudio/
    mv /etc/orkaudio/config-devel.xml /etc/orkaudio/config.xml
    sed -i -e "s|_PLUGINS_DIR_|$ORKAUDIO_DIR/plugins/|" /etc/orkaudio/config.xml
    sed -i -e "s|_CAPTURE_PLUGIN_DIR_|$ORKAUDIO_DIR/audiocaptureplugins/voip/.libs/|" /etc/orkaudio/config.xml

    printf "\n\n"
}


# check arguments
if [[ "$1" = "-h" || "$1" = "--help" ]]; then
    usage
elif [[ "$1" = "clean" ]]; then
    clean
elif [[ "$1" = "setup" ]]; then
    setup
else
    usage
fi

