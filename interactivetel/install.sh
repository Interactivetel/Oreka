#!/usr/bin/env bash
set -eE

cd "$(dirname "$0")"

. lib.sh


usage() {
  info "::: Description:"
  info ":::   Install OrkAudio in production or development mode"
  info ":::"
  info "::: Supported systems:"
  info ":::   Debian, Ubuntu, CentOS and RedHat."
  info ":::"
  info "::: Usage:"
  info ":::   $(basename $0) [ -h | -d <DESTDIR> ] [release | debug | dev]"
  info ":::"
  info ":::   -h: Show this message"
  info ":::   -d: install under this directory: DESTDIR"
  info ":::   release: install in release mode (optimizations on)"
  info ":::   debug: install in debug mode (optimizations off, debugging info on)"
  info ":::   dev: boostrap for develpment mode"
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
    sudo yum -y install apr-devel libpcap-devel xerces-c-devel libsndfile-devel \
      speex-devel libogg-devel openssl-devel log4cxx-devel libcap-devel
  elif [[ "$BASE_DIST" = "debian" ]]; then
    # update the system
    sudo apt-get -y update
    sudo apt-get -y upgrade

    # install development tools
    sudo apt-get -y install git curl wget mc htop libtool libtool-bin cmake sngrep net-tools dnsutils build-essential

    # orkaudio dependencies, log4cxx and log4cxx-devel: v0.10.0
    sudo apt-get -y install libapr1-dev libpcap-dev libboost-all-dev libxerces-c-dev libsndfile1-dev \
      libspeex-dev libopus-dev libssl-dev liblog4cxx-dev libcap-dev

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
  wget --no-check-certificate -P "$BUILD_DIR" https://packages.interactivetel.com/libs/opus-1.3.1.tar.gz
  tar -C "$BUILD_DIR" -xpf "$BUILD_DIR/$OPUS_LIB.tar.gz"

  pushd "$OPUS_DIR" &>/dev/null
  ./configure --enable-shared=no --enable-static --with-pic
  make clean
  make -j
  ln -sf "$OPUS_DIR/.libs/libopus.a" "$OPUS_DIR/.libs/libopusstatic.a"
  popd &>/dev/null

  printf "\n\n"

  # build silk codec
  header "Building Silk lib ..."
  wget --no-check-certificate -P "$BUILD_DIR" https://packages.interactivetel.com/libs/silk.tgz
  tar -C "$BUILD_DIR" -xpf "$BUILD_DIR/$SILK_LIB".tgz

  pushd "$SILK_DIR" &>/dev/null
  make clean
  CFLAGS="-fPIC" make -j lib
  popd &>/dev/null

  printf "\n\n"

  if [[ "$BASE_DIST" = "redhat" ]]; then
    # boost
    header "Installing boost library at: $BOOST_DIR"
    wget --no-check-certificate -P "$BUILD_DIR" https://packages.interactivetel.com/libs/boost_1_79_0.tar.gz
    tar -C "$BUILD_DIR" -xpf "$BUILD_DIR/$BOOST_LIB.tar.gz"
  fi

  # build G729 codec for all dist except debian 11 and up
  if [[ "$DIST" = "debian" && "$VER" -ge 11 ]]; then
    return
  fi

  header "Installing G729 lib"
  wget --no-check-certificate -P "$BUILD_DIR" https://packages.interactivetel.com/libs/bcg729-1.1.1.tar.gz
  tar -C "$BUILD_DIR" -xpf "$BUILD_DIR/$G729_LIB.tar.gz"

  pushd "$G729_DIR" &>/dev/null
  if [[ "$BASE_DIST" == "redhat" ]]; then
    cmake3 . -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_SHARED=YES -DENABLE_STATIC=NO -DCMAKE_SKIP_INSTALL_RPATH=ON
  else
    cmake . -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_SHARED=YES -DENABLE_STATIC=NO -DCMAKE_SKIP_INSTALL_RPATH=ON
  fi
  make clean
  make -j

  if [[ "$DEVEL" = false ]]; then
    $SUDO make DESTDIR=$DESTDIR install
  fi
  popd &>/dev/null

  printf "\n\n"
}

install_orkaudio() {
  CPPFLAGS="-DXERCES_3 -I$OPUS_DIR/include -I$SILK_DIR/interface -I$SILK_DIR/src -I$OPUS_DIR/include -I$G729_DIR/include"
  LDFLAGS="-Wl,-rpath=/usr/lib,-L$SILK_DIR -L$OPUS_DIR/.libs -L$(readlink -f ../orkbasecxx/.libs) -L$G729_DIR/src"
  if [[ "$BASE_DIST" = "redhat" ]]; then
    CPPFLAGS="$CPPFLAGS -I$BOOST_DIR"
  fi

  if [[ "$DEBUG" = true || "$DEVEL" = true ]]; then
    CFLAGS="-DDEBUG -g3 -ggdb3 -Og $CFLAGS"
    CXXFLAGS="-DDEBUG -g3 -ggdb3 -Og $CXXFLAGS"
    CPPFLAGS="-DDEBUG -g3 -ggdb3 -Og $CPPFLAGS"
  else
    CFLAGS="-O2 $CFLAGS"
    CXXFLAGS="-O2 $CXXFLAGS"
    CPPFLAGS="-O2 $CPPFLAGS"
  fi

  for DIR in orkbasecxx orkaudio; do
    if [[ "$DEVEL" == true ]]; then
      header "Boostraping $DIR for DEVELOPMENT mode"
    elif [[ "$DEBUG" == true ]]; then
      header "Installing $DIR in DEBUG mode under: $DESTDIR"
    else
      header "Installing $DIR in RELEASE mode under: $DESTDIR"
    fi

    pushd "../$DIR" &>/dev/null
    test -f Makefile && make distclean
    autoreconf -f -i
    ./configure CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" CPPFLAGS="$CPPFLAGS" LDFLAGS="$LDFLAGS"
    make -j

    # install if not in development mode
    test "$DEVEL" = false &&  $SUDO make DESTDIR=$DESTDIR install
    popd &>/dev/null
    printf "\n\n"
  done
}

install_conf() {
  header "Installing configuration files and finishing installation"

  # copy all configuration files
  $SUDO mkdir -p $DESTDIR/etc/orkaudio
  $SUDO mkdir -p $DESTDIR/var/log/orkaudio
  $SUDO cp -f conf/* $DESTDIR/etc/orkaudio/

  if [[ "$DEVEL" = true ]]; then
    ORKAUDIO_DIR=$(readlink -f ../orkaudio)
    $SUDO chown -R "$USER:$USER" "$DESTDIR/etc/orkaudio"
    $SUDO chown -R "$USER:$USER" "$DESTDIR/var/log/orkaudio"
    $SUDO mv "$DESTDIR/etc/orkaudio/config-devel.xml" "$DESTDIR/etc/orkaudio/config.xml"
    $SUDO sed -i -e "s|_PLUGINS_DIR_|$ORKAUDIO_DIR/plugins/|" "$DESTDIR/etc/orkaudio/config.xml"
    $SUDO sed -i -e "s|_CAPTURE_PLUGIN_DIR_|$ORKAUDIO_DIR/audiocaptureplugins/voip/.libs/|" "$DESTDIR/etc/orkaudio/config.xml"
    $SUDO sed -i -e "s|_USER_|$USER|" "$DESTDIR/etc/orkaudio/config.xml"
  else
    $SUDO rm -f $DESTDIR/etc/orkaudio/config-devel.xml
  fi

    printf "\n\n"
}

install_all() {
  system-detect
  if [[ "$BASE_DIST" != "debian" && "$BASE_DIST" != "redhat" ]]; then
    abort "Unsupported linux distribution: $OS/$DIST, we only support Debian and CentOS linux distros"
  fi

  SUDO=
  if ! is-writable "$DESTDIR"; then
    SUDO=sudo
  fi

  # VARS
  BUILD_DIR=$(readlink -f ../.build-"$OS-$DIST-$VER"/)

  OPUS_LIB=opus-1.3.1
  OPUS_DIR="$BUILD_DIR/$OPUS_LIB"

  SILK_LIB=silk
  SILK_DIR="$BUILD_DIR/$SILK_LIB/SILKCodec/SILK_SDK_SRC_FIX"

  G729_LIB=bcg729-1.1.1
  G729_DIR="$BUILD_DIR/$G729_LIB"

  BOOST_LIB=boost_1_79_0
  BOOST_DIR="$BUILD_DIR/$BOOST_LIB"

  # clean the build directory
  rm -rf "$BUILD_DIR"

  install_binary_deps
  if [[ "$BASE_DIST" = "redhat" ]]; then
    source /opt/rh/devtoolset-9/enable
  fi

  # install orkaudio
  install_source_deps
  install_orkaudio
  install_conf

  printf "\n\n"
}

DESTDIR=
DEBUG=false
DEVEL=false
while getopts ":hd:" OPT; do
  case "$OPT" in
  h)
    usage
    exit 0
    ;;
  d)
    DESTDIR="$OPTARG"
    ;;
  :)
    abort "$(basename $0): Must supply an argument to -$OPTARG"
    ;;
  ?)
    abort "$(basename $0): Invalid option: -${OPTARG}"
    ;;
  esac
done

# skip all parsed options and check if there are more options, 
shift $(( OPTIND - 1 ))
if [[ $# -eq 0 ]]; then
  usage
elif [[ $# -eq 1 ]]; then
  if [[ "$1" = "release" ]]; then
    install_all
  elif [[ "$1" = "debug" ]]; then
    DEBUG=true
    install_all
  elif [[ "$1" = "dev" ]]; then
    DEVEL=true
    DEBUG=true
    install_all
  else
    abort "$(basename $0): Invalid install mode: '$1', it must be one of: [release, debug, dev]"
  fi
elif [[ $# -gt 1 ]]; then
  abort "$(basename $0): Invalid number of options: '$*'"
fi
