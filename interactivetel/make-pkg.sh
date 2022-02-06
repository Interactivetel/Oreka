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
    info ":::   make-pkg.sh [ -h | --help ]"
    info ":::"
    info ":::   -h | --help: Show this message"
    info ":::   The script will automatically detect you linux distro and create the package (rpm|deb) accordingly"
    info ":::"
    info "::: Ej:"
    info ":::   ./make-pkg.sh"
    info ":::"
}

make-package() {
    # detect the running we are running on
    system-detect

    if [[ "$OS" != "linux" ]]; then
      abort "Unsupported operating system: $OS, we only support linux"
    fi

    # check for FPM command and install it if not found
    command -v fpm &>/dev/null || {
        header "Installing FPM ..."
        if [[ "$BASE_DIST" = "debian" ]]; then
            sudo apt-get -y install ruby 
            sudo gem install fpm
        elif [[ "$BASE_DIST" = "redhat" ]]; then
            # fix centos 6 repositories (EOL)
            fix-centos6-repos
            
            command -v rvm || {
                command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
                command curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
                curl -sSL https://get.rvm.io | bash -s stable
            }

            source ~/.rvm/scripts/rvm
            command -v ruby || rvm install ruby
            command -v fpm || gem install fpm
        else
            abort "Could not found command: fpm, please, install it first"
        fi
    }

    # check we defined proper version numbers
    source ./version.txt
    test -z "$VERSION" && abort "Invalid version number, check version.txt for the VERSION variable"
    test -z "$ITER" && abort "Invalid iteration number, check version.txt for the ITER variable"
    test -z "$DIST" && abort "Cannot detect distribution name"
    test -z "$VER" && abort "Cannot detect distribution version"


    # install orkaudio
    VM="$DIST-$VER"
    header "Installing OrkAudio at $(readlink -f ./packages/$VM)"
    # rm -rf "./packages/$VM"
    # ./install.sh $(readlink -f "./packages/$VM")

    # remove static libs
    find "./packages/$VM" -name "*.la" -type f -exec rm {} +
    find "./packages/$VM" -name "*.a" -type f -exec rm {} +

    # finally make the package with FPM
    if [[ "$BASE_DIST" == "redhat" ]]; then
        TAG=$(echo $VER | cut -d '.' -f 1)
        fpm \
            -s dir -t rpm --force --package "./packages/$VM" --chdir "./packages/$VM" \
            --name orkaudio --version "$VERSION" --iteration "$ITER" \
            --license "IAT" --vendor "InteractiveTel" \
            --maintainer 'Jose Rodriguez Bacallao <jrodriguez@interactivetel.com>' \
            --description 'VoIP Call Recording Platform' \
            --url 'https://interactivetel.com/totaltrack' --category 'Applications/Communications' \
            -d apr-devel -d libpcap-devel -d boost-devel -d xerces-c-devel -d libsndfile-devel \
            -d speex-devel -d libogg-devel -d openssl-devel -d log4cxx-devel -d libcap-devel \
            --after-install "./dist/after-install.sh" \
            --before-remove "./dist/before-remove.sh" \
            --after-upgrade "./dist/after-upgrade.sh" \
            --rpm-compression xz --rpm-dist "el$TAG" \
            --config-files /etc/orkaudio \
            --directories /usr/lib/orkaudio --directories /var/log/orkaudio \
            --directories /etc/orkaudio --directories /usr/share/Bcg729 --directories /usr/include/bcg729 \
            etc/orkaudio usr/ var/log/orkaudio
    elif [[ "$BASE_DIST" == "debian" ]]; then
        EXTRA_DIRS=""
        if [[ "$DIST" == "debian" && "$VER" -lt 11 ]]; then
            EXTRA_DIRS="--directories /usr/share/Bcg729 --directories /usr/include/bcg729"
        fi

        fpm \
            -s dir -t deb --force --package "./packages/$VM" --chdir "./packages/$VM" \
            --name orkaudio --version "$VERSION" --iteration "$ITER" \
            --license "IAT" --vendor "InteractiveTel" \
            --maintainer 'Jose Rodriguez Bacallao <jrodriguez@interactivetel.com>' \
            --description 'VoIP Call Recording Platform' \
            --url 'https://interactivetel.com/totaltrack' --category 'comm' \
            -d libapr1-dev -d libpcap-dev -d libboost-all-dev -d libxerces-c-dev -d libsndfile1-dev \
            -d libspeex-dev -d libopus-dev  -d libssl-dev -d liblog4cxx-dev -d libcap-dev \
            --after-install "./dist/after-install.sh" \
            --before-remove "./dist/before-remove.sh" \
            --after-upgrade "./dist/after-upgrade.sh" \
            --deb-recommends "orkaudio" \
            --deb-compression xz --deb-dist stable \
            --config-files /etc/orkaudio \
            --directories /usr/lib/orkaudio --directories /var/log/orkaudio \
            --directories /etc/orkaudio $EXTRA_DIRS \
            etc/orkaudio usr/ var/log/orkaudio
    else
        abort "Unsupported linux distribution: $BASE_DIST/$DIST-$VER"
    fi
    
}

if [[ $# -eq 0 ]]; then
    make-package
elif [[ $# -eq 1 ]]; then
    if [[ "$1" = "-h" || "$1" = "--help" ]]; then
        usage
    fi
else
    abort "Invalid options, check the help: $*"
fi
