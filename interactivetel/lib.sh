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


CENTOS_REPO=$(cat << EOM
[C6.10-base]
name=CentOS-6.10 - Base
baseurl=https://packages.interactivetel.com/centos/6.10/os/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1
metadata_expire=never

[C6.10-updates]
name=CentOS-6.10 - Updates
baseurl=https://packages.interactivetel.com/centos/6.10/updates/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1
metadata_expire=never

[C6.10-extras]
name=CentOS-6.10 - Extras
baseurl=https://packages.interactivetel.com/centos/6.10/extras/\$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
enabled=1
metadata_expire=never
EOM
)

EPEL_REPO=$(cat << EOM
[epel]
name=Extra Packages for Enterprise Linux 6 - \$basearch
baseurl=https://packages.interactivetel.com/centos/6.10/epel/\$basearch/
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
EOM
)

SCL_REPO=$(cat << EOM
[centos-sclo-sclo]
name=CentOS-6 - SCLo sclo
baseurl=https://packages.interactivetel.com/centos/6.10/sclo/\$basearch/sclo/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
EOM
)

SCL_RH_REPO=$(cat << EOM
[centos-sclo-rh]
name=CentOS-6 - SCLo rh
baseurl=https://packages.interactivetel.com/centos/6.10/sclo/\$basearch/rh/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo
EOM
)

TOTALTRACK_REPO=$(cat << EOM
[totaltrack]
name=TotalTrack
baseurl=https://totaltrack:_PASSWD_@packages.interactivetel.com/centos/6.10/totaltrack/x86_64/
enabled=1
gpgcheck=0
EOM
)

SNGREP_REPO=$(cat << EOM
[sngrep]
name=Sngrep RPMs repository
baseurl=https://packages.interactivetel.com/centos/6.10/sngrep/x86_64/
enabled=1
gpgcheck=1
EOM
)

GIT_REPO=$(cat << EOM
[WANdisco-git]
name=WANdisco Distribution of git
baseurl=https://packages.interactivetel.com/centos/6.10/git/x86_64/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-WANdisco
EOM
)

MARIADB_REPO=$(cat << EOM
[mariadb]
name = MariaDB
baseurl = https://packages.interactivetel.com/centos/6.10/mariadb/x86_64/
gpgkey=https://packages.interactivetel.com/centos/6.10/mariadb/x86_64/RPM-GPG-KEY-MariaDB
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
    # totaltrack
    echo "$TOTALTRACK_REPO" | sudo tee /etc/yum.repos.d/totaltrack.repo >/dev/null 2>&1
    if [[ -z "$TT_PASSWD" ]]; then
      read -r -s -p "Password for TotalTrack repository: " TT_PASSWD
    fi
    sudo sed -i -e "s/_PASSWD_/$TT_PASSWD/" /etc/yum.repos.d/totaltrack.repo

    # recent version of git
    if ! rpm -ql wandisco-git-release >/dev/null 2>&1; then
      sudo yum -y install https://packages.interactivetel.com/centos/6.10/git/x86_64/wandisco-git-release-6-1.noarch.rpm
    fi
    sudo rm -f /etc/yum.repos.d/wandisco-git*
    echo "$GIT_REPO" | sudo tee /etc/yum.repos.d/wandisco-git.repo >/dev/null 2>&1

    # sngrep
    sudo rm -f /etc/yum.repos.d/irontec.repo
    echo "$SNGREP_REPO" | sudo tee /etc/yum.repos.d/sngrep.repo >/dev/null 2>&1
    sudo rpm --import https://packages.interactivetel.com/centos/6.10/sngrep/x86_64/public.key

    # mariadb
    echo "$MARIADB_REPO" | sudo tee /etc/yum.repos.d/mariadb.repo >/dev/null 2>&1
  elif [[ "$BASE_DIST" == "debian" ]]; then
    # totaltrack
    echo -e "\n\n## IAT" | tee -a /etc/apt/sources.list >/dev/null 2>&1
    echo "deb [trusted=yes] https://packages.interactivetel.com/debian/$VER/x86_64 ./" | sudo tee -a /etc/apt/sources.list >/dev/null 2>&1
  fi
  printf "\n"
}

fix-centos6-repos() {
  # must run system-detect first
  if [[ "$BASE_DIST" = "redhat" && $(echo "$VER" | cut -d '.' -f 1) -eq 6 ]]; then
    # base
    sudo rm -f /etc/yum.repos.d/*
    echo "$CENTOS_REPO" | sudo tee /etc/yum.repos.d/CentOS-Base.repo >/dev/null 2>&1

    # fix ssl issues
    sudo yum -y update ca-certificates nss curl

    # fix epel
    if ! rpm -ql epel-release >/dev/null 2>&1; then
      sudo yum -y install epel-release
    fi
    sudo rm -f /etc/yum.repos.d/epel*
    echo "$EPEL_REPO" | sudo tee /etc/yum.repos.d/epel.repo >/dev/null 2>&1

    # fix scl
    if ! rpm -ql centos-release-scl >/dev/null 2>&1; then
      sudo yum -y install centos-release-scl
    fi

    if ! rpm -ql centos-release-scl-rh >/dev/null 2>&1; then
      sudo yum -y install centos-release-scl-rh
    fi

    sudo rm -f /etc/yum.repos.d/CentOS-SCL*
    echo "$SCL_REPO" | sudo tee /etc/yum.repos.d/CentOS-SCLo-scl.repo >/dev/null 2>&1
    echo "$SCL_RH_REPO" | sudo tee /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo >/dev/null 2>&1
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
