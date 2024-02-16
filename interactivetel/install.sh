#!/usr/bin/env bash
set -eE

cd "$(dirname "$0")"

. lib.sh

system-detect


DESTDIR=${DESTDIR:-}
PREFIX=${PREFIX:-/usr}
DEBUG=${DEBUG:-false}

BUILD_DIR=$(readlink -f ../.build)

OPUS_LIB=opus-1.4
OPUS_DIR="$BUILD_DIR/$OPUS_LIB"

SILK_LIB=silk-1.0.9
SILK_DIR="$BUILD_DIR/$SILK_LIB"
SILK_SRC="$SILK_DIR/SILK_SDK_SRC_FIX"

G729_LIB=bcg729-1.1.1
G729_DIR="$BUILD_DIR/$G729_LIB"

BOOST_LIB=boost_1_84_0
BOOST_DIR="$BUILD_DIR/$BOOST_LIB"

CMAKE=cmake
if [[ "$BASE_DIST" == "redhat" ]]; then
  CMAKE=cmake3
fi

SUDO=
if [[ -n "$A" && -w "$(dirname "$A")" ]]; then
  SUDO=sudo
fi

usage() {
  info "::: Description:"
  info ":::   Install OrkAudio in production or development mode"
  info ":::"
  info "::: Supported systems:"
  info ":::   Debian, Ubuntu, CentOS and RedHat."
  info ":::"
  info "::: Usage:"
  info ":::   $(basename $0) <bin-deps | src-deps | clean | configure | install | rel | dev>"
  info ":::"
  info ":::   bin-deps: Install binary dependencies"
  info ":::   src-deps: Compile and install source dependencies"
  info ":::   clean: Clean the project"
  info ":::   configure: Run the configure step"
  info ":::   install: Build and install OrkAudio along with its configuration files"
  info ":::   rel: Build and install a release version of OrkAudio"
  info ":::   dev: Build and install a development (DEBUG ON) version of OrkAudio to: PROJECT_ROOT/.debug"
  info ":::"
  info "::: Enviroment Variables:"
  info ":::   DEBUG: Enables debug builds: true | false"
  info ":::   DESTDIR: Perform and staged install at this location"
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
    sudo apt-get -y install git curl wget mc htop libtool libtool-bin cmake sngrep net-tools dnsutils build-essential systemd-timesyncd

    # orkaudio dependencies, log4cxx and log4cxx-devel: v0.10.0
    sudo apt-get -y install libapr1-dev libpcap-dev libboost-all-dev libxerces-c-dev libsndfile1-dev \
      libspeex-dev libopus-dev libssl-dev liblog4cxx-dev libcap-dev

    # enable ntp service
    sudo systemctl enable --now systemd-timesyncd.service

    if [[ "$DIST" = "debian" && "$VER" -ge 11 ]]; then
      sudo apt-get -y install libbcg729-dev
    fi
  else
    abort "Unsupported linux distribution: $BASE_DIST/$DIST-$VER"
  fi

  printf "\n\n"
}

install_source_deps() {
  mkdir -p "$BUILD_DIR"

  # build opus codec
  header "Building Opus lib: $OPUS_DIR"
  rm -rf "$OPUS_DIR"
  wget https://github.com/Interactivetel/opus/archive/refs/tags/v1.4.tar.gz -O "$BUILD_DIR/$OPUS_LIB.tar.gz"
  tar -C "$BUILD_DIR" -xpf "$BUILD_DIR/$OPUS_LIB.tar.gz" && rm -f "$BUILD_DIR/$OPUS_LIB.tar.gz"

  pushd "$OPUS_DIR" &>/dev/null
  ./autogen.sh
  ./configure --enable-shared=yes --enable-static --with-pic
  make -j
  ln -sf "$OPUS_DIR/.libs/libopus.a" "$OPUS_DIR/.libs/libopusstatic.a"
  popd &>/dev/null
  printf "\n\n"

  # build silk codec
  header "Building Silk lib: $SILK_SRC"
  rm -rf "$SILK_DIR"
  git clone --depth 1 https://github.com/Interactivetel/SILKCodec "$SILK_DIR"

  pushd "$SILK_SRC" &>/dev/null
  CFLAGS="-fPIC" make -j clean lib
  popd &>/dev/null

  printf "\n\n"

  # boost
  if [[ "$BASE_DIST" = "redhat" ]]; then
    header "Installing boost library at: $BOOST_DIR"
    wget "https://boostorg.jfrog.io/artifactory/main/release/1.84.0/source/$BOOST_LIB.tar.gz" -O "$BUILD_DIR/$BOOST_LIB.tar.gz"
    tar -C "$BUILD_DIR" -xpf "$BUILD_DIR/$BOOST_LIB.tar.gz"
    printf "\n\n"
  fi

  # build G729 codec for all dist except debian 11 and up
  if [[ "$BASE_DIST" = "redhat" || "$DIST" = "debian" && "$VER" -le 10 ]]; then
    header "Builing G729 lib: $G729_DIR"
    rm -rf "$G729_DIR"
    wget https://github.com/Interactivetel/bcg729/archive/refs/tags/1.1.1.tar.gz -O "$BUILD_DIR/$G729_LIB.tar.gz"
    tar -C "$BUILD_DIR" -xpf "$BUILD_DIR/$G729_LIB.tar.gz" && rm -f "$BUILD_DIR/$G729_LIB.tar.gz"

    pushd "$G729_DIR" &>/dev/null
    $CMAKE . -DCMAKE_INSTALL_PREFIX="$PREFIX" -DENABLE_SHARED=YES -DENABLE_STATIC=YES -DCMAKE_SKIP_INSTALL_RPATH=ON
    make -j
    $SUDO make DESTDIR=$DESTDIR install
    popd &>/dev/null
  fi

  printf "\n\n"
}

configure() {
  CPPFLAGS="-DXERCES_3"
  CFLAGS="-I$OPUS_DIR/include -I$SILK_SRC/interface -I$SILK_SRC/src -I$G729_DIR/include"
  CXXFLAGS="-I$OPUS_DIR/include -I$SILK_SRC/interface -I$SILK_SRC/src -I$G729_DIR/include"
  LDFLAGS="-Wl,-rpath=/usr/lib,-L$SILK_SRC -L$OPUS_DIR/.libs -L$(readlink -f ../orkbasecxx/.libs) -L$G729_DIR/src"

  if [[ "$BASE_DIST" = "redhat" ]]; then
    CPPFLAGS="$CPPFLAGS -I$BOOST_DIR"
  fi

  if [[ "$DEBUG" = true ]]; then
    CPPFLAGS="-DDEBUG $CPPFLAGS"
    CFLAGS="-g3 -ggdb3 -Og $CFLAGS"
    CXXFLAGS="-g3 -ggdb3 -Og $CXXFLAGS"
  fi

  for PROJECT in orkbasecxx orkaudio; do
    pushd "../$PROJECT" &>/dev/null
    header "Configuring: $PROJECT"
    test -f Makefile && make distclean || :
    autoreconf -f -i
    echo $CPPFLAGS
    echo $CFLAGS
    echo $CXXFLAGS
    echo $LDFLAGS

    ./configure --prefix="$PREFIX" CPPFLAGS="$CPPFLAGS" CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS"
    printf "\n\n"
    popd &>/dev/null
  done
}

install() {
  for PROJECT in orkbasecxx orkaudio; do
    pushd "../$PROJECT" &>/dev/null
    header "Building: $PROJECT"
    make -j
    printf "\n\n"

    header "Installing: $PROJECT"
    $SUDO make DESTDIR=$DESTDIR install
    printf "\n\n"
    popd &>/dev/null
  done

  $SUDO mkdir -p $DESTDIR/etc/orkaudio
  $SUDO mkdir -p $DESTDIR/var/log/orkaudio
  $SUDO cp -f conf/* $DESTDIR/etc/orkaudio
}

clean() {
  test -d "$BUILD_DIR" && rm -rf "$BUILD_DIR"
  test -d $(readlink -f ../.debug) && rm -rf $(readlink -f ../.debug)
  for PROJECT in orkbasecxx orkaudio; do
    pushd "../$PROJECT" &>/dev/null
    if [[ -f Makefile ]]; then
      header "Cleaning: $PROJECT"
      make distclean
      printf "\n\n"
    fi
    popd &>/dev/null
  done
}

release() {
  DEBUG=false  
  clean
  install_binary_deps
  install_source_deps
  configure
  install

  $SUDO sed -i -E \
    -e "s|_PLUGINS_DIR_|/usr/lib/orkaudio/plugins/|" \
    -e "s|_AUDIO_DIR_|/var/log/orkaudio/audio|" \
    -e "s|_CAPTURE_PLUGIN_DIR_|/usr/lib|" \
    -e "s|_USER_|root|" \
    "$DESTDIR/etc/orkaudio/config.xml" 

  $SUDO sed -i -E \
    -e "s|_ORKAUDIO_LOG_|/var/log/orkaudio/orkaudio.log|" \
    -e "s|_MESSAGES_LOG_|/var/log/orkaudio/messages.log|" \
    -e "s|_TAPELIST_LOG_|/var/log/orkaudio/tapelist.log|" \
    "$DESTDIR/etc/orkaudio/logging.properties"
}

development() {
  DEBUG=true  
  DESTDIR=$(readlink -f "../.debug")
  clean
  install_binary_deps
  install_source_deps
  configure
  install

  $SUDO sed -i -E \
    -e "s|_PLUGINS_DIR_|$DESTDIR/usr/lib/orkaudio/plugins/|" \
    -e "s|_AUDIO_DIR_|$DESTDIR/var/log/orkaudio/audio|" \
    -e "s|_CAPTURE_PLUGIN_DIR_|$DESTDIR/usr/lib|" \
    -e "s|_USER_|$USER|" \
    "$DESTDIR/etc/orkaudio/config.xml"

  $SUDO sed -i -E \
    -e "s|_ORKAUDIO_LOG_|$DESTDIR/var/log/orkaudio/orkaudio.log|" \
    -e "s|_MESSAGES_LOG_|$DESTDIR/var/log/orkaudio/messages.log|" \
    -e "s|_TAPELIST_LOG_|$DESTDIR/var/log/orkaudio/tapelist.log|" \
    "$DESTDIR/etc/orkaudio/logging.properties"

  for FILENAME in config.xml logging.properties localpartymap.csv skinnyglobalnumbers.csv area-codes-recorded-side.csv; do
    ln -sf "$DESTDIR/etc/orkaudio/$FILENAME" "$DESTDIR/usr/sbin/$FILENAME"
  done
}

if [[ $# -eq 0 ]]; then
  usage
elif [[ $# -eq 1 ]]; then
  if [[ "$1" = "bin-deps" ]]; then
    install_binary_deps
  elif [[ "$1" = "src-deps" ]]; then
    install_source_deps
  elif [[ "$1" = "clean" ]]; then
    clean
  elif [[ "$1" = "configure" ]]; then
    configure
  elif [[ "$1" = "install" ]]; then
    install
  elif [[ "$1" = "rel" ]]; then
    release
  elif [[ "$1" = "dev" ]]; then
    development
  else
    abort "$(basename $0): Invalid option: '$1'"
  fi
elif [[ $# -gt 1 ]]; then
  abort "$(basename $0): Invalid number of options: '$*'"
fi

