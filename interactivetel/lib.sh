#!/usr/bin/env bash
# documentation for bash: http://wiki.bash-hackers.org/commands/classictest

# initialize the terminal with color support
if [[ -t 1 ]]; then
  # see if it supports colors...
  ncolors=$(tput colors)

  if [[ -n "$ncolors" && $ncolors -ge 8 ]]; then
    normal="$(tput sgr0)"
    red="$(tput setaf 1)"
    green="$(tput setaf 2)"
    yellow="$(tput setaf 3)"
    blue="$(tput setaf 4)"
    magenta="$(tput setaf 5)"
    cyan="$(tput setaf 6)"
    ul="$(tput smul)"
  fi
fi


CENTOS_ISO_REPO=$(cat << EOM
[C6.10-iso]
name=Centos-6.10 - ISO
baseurl=http://packages.interactivetel.com/centos6-iso/
enabled=1
gpgcheck=0
EOM
)

CENTOS_REPO=$(cat << EOM
[C6.10-base]
name=CentOS-6.10 - Base
baseurl=http://vault.centos.org/6.10/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1
metadata_expire=never

[C6.10-updates]
name=CentOS-6.10 - Updates
baseurl=http://vault.centos.org/6.10/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1
metadata_expire=never

[C6.10-extras]
name=CentOS-6.10 - Extras
baseurl=http://vault.centos.org/6.10/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1
metadata_expire=never

[C6.10-contrib]
name=CentOS-6.10 - Contrib
baseurl=http://vault.centos.org/6.10/contrib/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=0
metadata_expire=never

[C6.10-centosplus]
name=CentOS-6.10 - CentOSPlus
baseurl=http://vault.centos.org/6.10/centosplus/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=0
metadata_expire=never
EOM
)


EPEL_REPO=$(cat << EOM
[epel]
name=Extra Packages for Enterprise Linux 6 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/6/\$basearch
baseurl=https://archives.fedoraproject.org/pub/archive/epel/6/x86_64
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 6 - \$basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/6/\$basearch/debug
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-6&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 6 - \$basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/6/SRPMS
baseurl=https://archives.fedoraproject.org/pub/archive/epel/6/SRPMS
#mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-source-6&arch=\$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
gpgcheck=1
EOM
)


SCL_REPO=$(cat << EOM
[centos-sclo-sclo]
name=CentOS-6 - SCLo sclo
baseurl=http://vault.centos.org/centos/6/sclo/\$basearch/sclo/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-sclo-testing]
name=CentOS-6 - SCLo sclo Testing
baseurl=http://buildlogs.centos.org/centos/6/sclo/\$basearch/sclo/
gpgcheck=0
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-sclo-source]
name=CentOS-6 - SCLo sclo Sources
baseurl=http://vault.centos.org/centos/6/sclo/Source/sclo/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-sclo-debuginfo]
name=CentOS-6 - SCLo sclo Debuginfo
baseurl=http://debuginfo.centos.org/centos/6/sclo/\$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
EOM
)


SCL_RH_REPO=$(cat << EOM
[centos-sclo-rh]
name=CentOS-6 - SCLo rh
baseurl=http://vault.centos.org/centos/6/sclo/\$basearch/rh/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-rh-testing]
name=CentOS-6 - SCLo rh Testing
baseurl=http://buildlogs.centos.org/centos/6/sclo/\$basearch/rh/
gpgcheck=0
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-rh-source]
name=CentOS-6 - SCLo rh Sources
baseurl=http://vault.centos.org/centos/6/sclo/Source/rh/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo

[centos-sclo-rh-debuginfo]
name=CentOS-6 - SCLo rh Debuginfo
baseurl=http://debuginfo.centos.org/centos/6/sclo/\$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
EOM
)


TOTALTRACK_REPO=$(cat << EOM
[totaltrack]
name=TotalTrack
baseurl=http://packages.interactivetel.com/centos/6/x86_64/
enabled=1
gpgcheck=0
EOM
)


IRONTEC_REPO=$(cat << EOM
[irontec]
name=Irontec RPMs repository
baseurl=http://packages.irontec.com/centos/6/x86_64/
enabled=1
gpgcheck=1
EOM
)


header() {
  printf "$yellow#####################################################################$normal\n"
  printf "$yellow# $1 $normal\n"
  printf "$yellow#####################################################################$normal\n\n"
}

info() {
  printf "$yellow$1$normal\n"
}

error() {
  printf "$red$1$normal\n" >&2 ## Send message to stderr. Exclude >&2 if you don't want it that way.
}

warning() {
  printf "$magenta$1$normal\n" >&2 ## Send message to stderr. Exclude >&2 if you don't want it that way.
}

log() {
  LEVEL=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  MESSAGE=$2

  logger -t "[$LEVEL]" "$MESSAGE"
  if [[ $LEVEL == "WARNING" ]]; then
    warning "$MESSAGE"
  elif [[ $LEVEL == "ERROR" ]]; then
    error "$MESSAGE"
  else
    info "$MESSAGE"
  fi
}

abort() {
  test -n "$1" && error "$1"
  exit 1
}

install-custom-repos() {
  # must run system-detect first
  if [[ "$BASE_DIST" == "redhat" ]]; then
    echo "$TOTALTRACK_REPO" | sudo tee /etc/yum.repos.d/totaltrack.repo >/dev/null 2>&1
    echo "$IRONTEC_REPO" | sudo tee /etc/yum.repos.d/irontec.repo >/dev/null 2>&1
    sudo rpm --import http://packages.irontec.com/public.key || sudo rpm --import keys/irontec.key
  elif [[ "$BASE_DIST" == "debian" ]]; then
    echo -e "\n\n## IAT" | sudo tee -a /etc/apt/sources.list >/dev/null 2>&1
    echo "deb [trusted=yes] http://packages.interactivetel.com/debian/$VER/x86_64 ./" | sudo tee -a /etc/apt/sources.list >/dev/null 2>&1
    sudo apt-get -y update
  fi
  printf "\n"
}

fix-centos6-repos() {
  # must run system-detect first
  if [[ "$BASE_DIST" = "redhat" && $(echo "$VER" | cut -d '.' -f 1) -eq 6 ]]; then
    # fix ssl errors
    echo "$CENTOS_ISO_REPO" | sudo tee /etc/yum.repos.d/CentOS-ISO.repo >/dev/null 2>&1
    sudo yum -y update ca-certificates nss curl --disablerepo=*
    sudo rm -f /etc/yum.repos.d/CentOS-ISO.repo
    sudo yum clean all

    # base
    test -f /etc/yum.repos.d/CentOS-Base.repo && sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.old
    echo "$CENTOS_REPO" | sudo tee /etc/yum.repos.d/CentOS-Base.repo >/dev/null 2>&1

    # remove unused repositories
    sudo rm -f /etc/yum.repos.d/CentOS-fasttrack.repo* /etc/yum.repos.d/CentOS-Vault.repo* \
      /etc/yum.repos.d/CentOS-Debuginfo.repo* /etc/yum.repos.d/CentOS-Media.repo \
      /etc/yum.repos.d/*rpmforge* /etc/yum.repos.d/*rpmfusion*

    # fix epel
    sudo yum -y remove epel-release --disablerepo=*
    sudo rm -f /etc/yum.repos.d/epel*
    sudo yum -y install https://archives.fedoraproject.org/pub/archive/epel/6/x86_64/epel-release-6-8.noarch.rpm --disablerepo=*
    echo "$EPEL_REPO" | sudo tee /etc/yum.repos.d/epel.repo >/dev/null 2>&1

    # fix scl
    sudo yum -y remove centos-release-scl centos-release-scl-rh --disablerepo=*
    sudo rm -f /etc/yum.repos.d/CentOS-SCL*
    sudo yum -y install centos-release-scl centos-release-scl-rh
    echo "$SCL_REPO" | sudo tee /etc/yum.repos.d/CentOS-SCLo-scl.repo >/dev/null 2>&1
    echo "$SCL_RH_REPO" | sudo tee /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo >/dev/null 2>&1
    sudo rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-SIG-SCLo || sudo rpm --import keys/scl.key
  fi

  printf "\n"
}

system-detect() {
  # This function will set the following enviroment variables:
  # OS: Operation system, Ej: Darwin, Linux
  # KERNEL: Kervel version, Ej: 2.6.32-696.30.1.el6.x86_64
  # ARCH: System architecture, Ej: x86_64
  # DIST: Distibution ID, Ej: debian, ubuntu, centos, redhat
  # VER: Distribution version: Ej: 18.04, 9.6
  OS=$(uname | tr '[:upper:]' '[:lower:]')
  KERNEL=$(uname -r | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m | tr '[:upper:]' '[:lower:]')
  BASE_DIST=""
  DIST=""
  VER=""

  if [[ "$OS" == "darwin" ]]; then # OSX
    BASE_DIST="macos"
    DIST="macos"
    VER=$(sw_vers -productVersion | tr '[:upper:]' '[:lower:]')
  else # Linux
    if [ -f /etc/os-release ]; then
      BASE_DIST=$(cat /etc/os-release | sed -rn 's/^ID_LIKE="?(\w+)"?.*/\1/p' | tr '[:upper:]' '[:lower:]')
      DIST=$(cat /etc/os-release | sed -rn 's/^ID="?(\w+)"?.*/\1/p' | tr '[:upper:]' '[:lower:]')
      VER=$(cat /etc/os-release | sed -rn 's/^VERSION_ID="?([0-9\.]+)"?.*/\1/p' | tr '[:upper:]' '[:lower:]')
    elif [ -f /etc/redhat-release ]; then
      BASE_DIST="redhat"
      DIST=$(sed -rn 's/^(\w+).*/\1/p' /etc/redhat-release | tr '[:upper:]' '[:lower:]')
      VER=$(sed -rn 's/.*([0-9]+\.[0-9]+).*/\1/p' /etc/redhat-release | tr '[:upper:]' '[:lower:]')
    fi

    if [[ "$DIST" == "debian" || "$DIST" == "ubuntu" ]]; then
      BASE_DIST=debian
    elif [[ "$DIST" == "centos" || "$DIST" == "redhat" || "$DIST" == "redhatenterpriseserver" ]]; then
      BASE_DIST=redhat
    fi

  fi
}

is-writable() {
  if [[ -d "$1" ]]; then
    if [[ -w "$1" ]]; then
      return 0
    fi
    return 1
  else
    if ! mkdir -p "$1" >/dev/null 2>&1; then
      return 1
    else
      rmdir "$1"
      return 0
    fi
  fi
}


### vagrant related stuff
is-vm-running() {
  if vagrant status "$1" --no-tty | grep running >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

start-vm() {
  if ! is-vm-running "$1"; then
    vagrant up "$1"
  fi
}

shutdown-vm() {
  if is-vm-running "$1"; then
    vagrant halt "$1"
  fi
}

trap 'abort "::: Unexpected error on line: $LINENO: ${BASH_COMMAND}"' ERR
