#!/usr/bin/env bash
set -eE

cd "$(dirname "$0")"

. lib.sh

header "Uninstalling OrkAudio"

# backup old config
test -d /etc/orkaudio && {
  BACKUP=$HOME/orkaudio-config-$(date +%Y%m%d-%H%M%S).tar.gz
  info "Backing up old configuration to: $BACKUP"
  tar -C /etc/orkaudio/ -czpf $BACKUP .
}

# remove all orkaudio packages and dependencies
system-detect
if command -v yum &>/dev/null; then
  sudo yum -y remove apr-devel libpcap-devel xerces-c-devel libsndfile-devel speex-devel libogg-devel openssl-devel log4cxx log4cxx-devel libcap-devel
  for PKG in orkspeex orkbase orkbasecxx orkaudio; do
    rpm -q "$PKG" && sudo yum -y remove "$PKG"
  done
elif command -v apt-get &>/dev/null; then
  sudo apt-get -y purge libapr1-dev libpcap-dev libboost-all-dev libxerces-c-dev libsndfile1-dev libspeex-dev libopus-dev libssl-dev liblog4cxx-dev libcap-dev libbcg729-dev
  for PKG in orkspeex orkbase orkbasecxx orkaudio; do
    dpkg -l "$PKG" && sudo apt-get -y purge "$PKG"
  done
  sudo apt-get -y autoremove
fi

# remove any remaining file just in case
sudo rm -rf /usr/include/bcg729 /usr/lib/pkgconfig/libbcg729.pc /usr/lib/libbcg729.* /usr/lib64/libbcg729.* /usr/lib/libgenerator.* /usr/lib/liborkbase.* \
  /usr/lib/libvoip.* /usr/lib64/pkgconfig/libbcg729.pc /usr/lib/x86_64-linux-gnu/libbcg729.* /usr/lib/x86_64-linux-gnu/pkgconfig/libbcg729.pc \
  /usr/lib/orkaudio /usr/share/Bcg729 /usr/sbin/orkaudio /etc/orkaudio /var/log/orkaudio

# disable boot service if any, including supervisor
test -f /etc/supervisor/conf-available/orkaudio.conf && sudo rm -f /etc/supervisor/conf-available/orkaudio.conf
test -f /etc/supervisor/conf.d/orkaudio.conf && sudo rm -f /etc/supervisor/conf.d/orkaudio.conf
if command -v chkconfig &>/dev/null && chkconfig orkaudio; then
  sudo chkconfig orkaudio off
  sudo chkconfig --del orkaudio
  test -f /etc/init.d/orkaudio && sudo rm -f /etc/init.d/orkaudio
fi

info "\nFinished!\n"
