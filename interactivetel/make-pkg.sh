#!/usr/bin/env bash
set -eE
cd "$(dirname "$0")"

. lib.sh


usage() {
    info "::: Description:"
    info ":::   Create a binary package (rpm, dep) for OrkAudio."
    info ":::"
    info "::: Supported systems:"
    info ":::   Debian, Ubuntu, CentOS and RedHat."
    info ":::"
    info "::: Usage:"
    info ":::   make-pkg.sh [ -h | --help ] <release|debug>"
    info ":::"
    info ":::   -h | --help: Show this message"
    info ":::   release: Creates the release (production ready) version of the package"
    info ":::   debug: Creates the debug version of the package"
    info ":::"
    info ":::   The script will automatically detect you linux distro and create the package (rpm|deb) accordingly"
    info ":::"
    info "::: Ej:"
    info ":::   ./make-pkg.sh"
    info ":::"
}


install_fpm() {
    command -v fpm &>/dev/null && return

    header "Installing FPM ..."
    system-detect
    if [[ "$BASE_DIST" = "debian" ]]; then
        sudo apt-get -y install ruby 
        sudo gem install fpm
    elif [[ "$BASE_DIST" = "redhat" ]]; then
        fix-centos6-repos
        command -v rvm || {
            command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
            command curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
            curl -sSL https://get.rvm.io | bash -s stable
        }

        source ~/.rvm/scripts/rvm
        command -v ruby || rvm install ruby
        gem install fpm
    else
        abort "Could not found command: fpm, please, install it first"
    fi
}

make-package() {
    # install fpm first
    install_fpm

    # check we defined proper version numbers
    source ./version.txt
    test -z "$VERSION" && VERSION=1.0
    test -z "$ITER" && ITER=0
    
    # install orkaudio in release mode
    INSTALL_DIR=$(mktemp -d -t orkaudio.XXX)
    # trap 'rm -rf "${INSTALL_DIR}"' EXIT
    DESTDIR="$INSTALL_DIR" ./install.sh rel

    # remove static libs and libtools artifacts
    find "$INSTALL_DIR" -name "*.la" -type f -exec rm {} +
    find "$INSTALL_DIR" -name "*.a" -type f -exec rm {} +

    # finally make the package with FPM
    if [[ "$BASE_DIST" == "redhat" ]]; then
        TAG=$(echo $VER | cut -d '.' -f 1)
        fpm \
            -s dir -t rpm --force --chdir "$INSTALL_DIR" \
            --name orkaudio --version "$VERSION" --iteration "$ITER" \
            --license "IAT" --vendor "InteractiveTel" \
            --maintainer 'Jose Rodriguez Bacallao <jrodriguez@interactivetel.com>' \
            --description 'VoIP Call Recording Platform' \
            --url 'https://interactivetel.com/totaltrack' --category 'Applications/Communications' --provides "orkaudio" \
            -d apr-devel -d libpcap-devel -d xerces-c-devel -d libsndfile-devel \
            -d speex-devel -d libogg-devel -d openssl-devel -d log4cxx-devel -d libcap-devel \
            --after-install "./dist/after-install.sh" \
            --before-remove "./dist/before-remove.sh" \
            --after-upgrade "./dist/after-upgrade.sh" \
            --rpm-compression xz --rpm-dist "el$TAG" \
            --config-files /etc/orkaudio \
            --directories /usr/lib/orkaudio --directories /var/log/orkaudio \
            --directories /etc/orkaudio --directories /usr/share/Bcg729 --directories /usr/include/bcg729
    elif [[ "$BASE_DIST" == "debian" ]]; then
        EXTRA_DIRS=""
        if [[ "$DIST" == "debian" && "$VER" -lt 11 ]]; then
            EXTRA_DIRS="--directories /usr/share/Bcg729 --directories /usr/include/bcg729"
        fi

        fpm \
            -s dir -t deb --force --chdir "$INSTALL_DIR" \
            --name orkaudio --version "$VERSION" --iteration "$ITER~$DIST$VER" \
            --license "IAT" --vendor "InteractiveTel" \
            --maintainer 'Jose Rodriguez Bacallao <jrodriguez@interactivetel.com>' \
            --description 'VoIP Call Recording Platform' \
            --url 'https://interactivetel.com/totaltrack' --category 'comm' --provides "orkaudio" \
            -d libapr1-dev -d libpcap-dev -d libboost-all-dev -d libxerces-c-dev -d libsndfile1-dev \
            -d libspeex-dev -d libopus-dev  -d libssl-dev -d liblog4cxx-dev -d libcap-dev \
            --after-install "./dist/after-install.sh" \
            --before-remove "./dist/before-remove.sh" \
            --after-upgrade "./dist/after-upgrade.sh" \
            --deb-compression xz --deb-dist stable \
            --config-files /etc/orkaudio \
            --directories /usr/lib/orkaudio --directories /var/log/orkaudio $EXTRA_DIRS
    else
        abort "Unsupported linux distribution: $BASE_DIST/$DIST-$VER"
    fi
    
}


if [[ $# -eq 0 ]]; then
    make-package
elif [[ $# -eq 1 && "$1" = "-h" || "$1" = "--help" ]]; then
    usage
else
    abort "$(basename $0): Invalid options, run: $(basename $0) -h | --help"
fi
