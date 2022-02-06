#!/usr/bin/env bash
set -eE

cd "$(dirname "$0")"

. lib.sh

SUDO=""
DESTDIR=""

BUILD_DIR=$(mktemp -d -t orkaudio.XXX)
trap 'rm -rf "${BUILD_DIR}"' EXIT

OPUS_LIB=opus-1.3.1
OPUS_DIR="$BUILD_DIR/$OPUS_LIB"

SILK_LIB=silk
SILK_DIR="$BUILD_DIR/$SILK_LIB/SILKCodec/SILK_SDK_SRC_FIX"

G729_LIB=bcg729-1.1.1
G729_DIR="$BUILD_DIR/$G729_LIB"

usage() {
    info "::: Description:"
    info ":::   Install OrkAudio into the system."
    info ":::"
    info "::: Supported systems:"
    info ":::   Debian, Ubuntu, CentOS and RedHat."
    info ":::"
    info "::: Usage:"
    info ":::   install.sh [ -h | --help | DESTDIR ]"
    info ":::"
    info ":::   -h | --help: Show this message"
    info ":::   DESTDIR: Install into this directory, for instance, staged installs"
    info ":::"
    info "::: Files:"
    info ":::   /usr/sbin/orkaudio"
    info ":::   /etc/orkaudio/config.xml"
    info ":::   /etc/orkaudio/localpartymap.csv"
    info ":::   /etc/orkaudio/skinnyglobalnumbers.csv"
    info ":::   /etc/orkaudio/area-codes-recorded-side.csv"
    info ":::   /etc/orkaudio/logging.properties"
    info ":::   /usr/lib/libgenerator.*"
    info ":::   /usr/lib/libvoip.*"
    info ":::   /usr/lib/liborkbase.*"
    info ":::   /usr/lib/orkaudio/plugins/librtpmixer.*"
    info ":::   /usr/lib/orkaudio/plugins/libsilkcodec.*"
    info ":::   /usr/lib/orkaudio/plugins/libg729codec.*"
    info ":::   /var/log/orkaudio/*.log"
    info ":::   /var/log/orkaudio/audio/*"
    info ":::"
}


install_binary_deps() {
    header "Installing binary dependencies"

    # install base dependencies
    if [[ "$BASE_DIST" = "redhat" ]]; then
        # fix centos 6 repositories (EOL)
        fix-centos6-repos

        # install custom repositories
        install-custom-repos

        # update the system
        sudo yum -y update

        # install development tools
        sudo yum install -y git curl wget mc htop libtool rpmdevtools devtoolset-9 cmake3 sngrep \
            net-tools bind-utils

        # orkaudio dependencies, log4cxx and log4cxx-devel: v0.10.0
        sudo yum -y install apr-devel libpcap-devel boost-devel xerces-c-devel libsndfile-devel \
            speex-devel libogg-devel openssl-devel log4cxx log4cxx-devel
    elif [[ "$BASE_DIST" = "debian" ]]; then
        # update the system
        sudo apt-get -y update
        sudo apt-get -y upgrade

        # install development tools
        sudo apt-get -y install git curl wget mc htop libtool cmake sngrep net-tools dnsutils build-essential 
        
        # orkaudio dependencies, log4cxx and log4cxx-devel: v0.10.0
        sudo apt-get -y install libapr1-dev libpcap-dev libboost-all-dev libxerces-c-dev libsndfile1-dev \
            libspeex-dev libopus-dev  libssl-dev liblog4cxx-dev

        if [[ "$DIST" = "debian" && "$VER" -ge 11 ]]; then
            sudo apt-get -y install libbcg729-dev
        fi
    else
        abort "Unsupported linux distribution: $BASE_DIST/$DIST-$VER"
    fi

    printf "\n\n"
}


install_source_deps() {
    # build opus codec
    header "::: Building Opus lib"
    tar -C "$BUILD_DIR" -xvpf "libs/$OPUS_LIB.tar.gz"

    pushd "$OPUS_DIR" &> /dev/null
    ./configure --enable-shared=no --with-pic
    make clean
    make -j4
    ln -sf "$OPUS_DIR/.libs/libopus.a" "$OPUS_DIR/.libs/libopusstatic.a"
    popd &> /dev/null

    printf "\n\n"

    # build silk codec
    header "Building Silk lib ...\n\n"
    tar -C "$BUILD_DIR" -xvpf "libs/$SILK_LIB".tgz

    pushd "$SILK_DIR" &> /dev/null
    make clean
    CFLAGS="-fPIC" make -j4 lib
    popd &> /dev/null

    printf "\n\n"

    # build G729 codec
    if [[ "$DIST" = "debian" && "$VER" -ge 11 ]]; then
        return
    fi
    
    header "Installing G729 lib"
    tar -C "$BUILD_DIR" -xvpf "libs/$G729_LIB.tar.gz"

    pushd "$G729_DIR" &> /dev/null
    if [[ "$BASE_DIST" == "redhat" ]]; then
        cmake3 . -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_SHARED=YES -DENABLE_STATIC=NO -DCMAKE_SKIP_INSTALL_RPATH=ON
    else
        cmake . -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_SHARED=YES -DENABLE_STATIC=NO -DCMAKE_SKIP_INSTALL_RPATH=ON
    fi
    make clean
    make -j4
    $SUDO make DESTDIR=$DESTDIR install
    popd &> /dev/null

    printf "\n\n"
}

install_orkbasecxx() {
    header "Installing OrkBaseCXX"

    # copy orkbasecxx to the build dir
    cp -a ../orkbasecxx "$BUILD_DIR"

    # build and install orkaudio
    pushd "$BUILD_DIR/orkbasecxx" &> /dev/null
    autoreconf  -f -i
    ./configure --prefix=/usr CXX=g++ LDFLAGS="-L$OPUS_DIR/.libs" CPPFLAGS="-DXERCES_3 -I$OPUS_DIR/include"
    make clean
    make -j4
    $SUDO make DESTDIR=$DESTDIR install
    popd &> /dev/null

    printf "\n\n"
}

install_orkaudio() {
    header "Installing OrkAudio"

    # copy orkbasecxx to the build dir
    cp -a ../orkaudio "$BUILD_DIR"

    pushd "$BUILD_DIR/orkaudio" &> /dev/null
    autoreconf  -f -i
    ./configure --prefix=/usr CXX=g++ \
        LDFLAGS="-Wl,-rpath=/usr/lib,-L$SILK_DIR -L$OPUS_DIR/.libs -L$(readlink -f ../orkbasecxx/.libs) -L$G729_DIR/src" \
        CPPFLAGS="-I$SILK_DIR/interface -I$SILK_DIR/src -I$OPUS_DIR/include -I$G729_DIR/include"
    make clean
    make -j4
    $SUDO make DESTDIR=$DESTDIR install
    popd &> /dev/null

    printf "\n\n"
}

install_all() {
    DESTDIR="$1"
    if ! is-writable "$DESTDIR"; then
        SUDO=sudo
    fi

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
    install_orkbasecxx
    install_orkaudio

    # copy all configuration files
    $SUDO cp -f conf/* $DESTDIR/etc/orkaudio/
    $SUDO rm -f $DESTDIR/etc/orkaudio/config-devel.xml

    printf "\n\n"
}


# check arguments
if [[ "$1" = "-h" || "$1" = "--help" ]]; then
    usage
else
    install_all $1
fi

