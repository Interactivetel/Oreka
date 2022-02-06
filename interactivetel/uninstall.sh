#!/usr/bin/env bash
set -eE

cd "$(dirname "$0")" 

. lib.sh


if [[ ! $EUID -eq 0 ]]; then
    abort "::: Must be root to run this script"
fi

# detect the linux distribution
system-detect
if [[ "$BASE_DIST" == "redhat" ]]; then
    PKG_MANAGER="yum"
    CHECK_CMD="rpm -q"
elif [[ "$BASE_DIST" == "debian" ]]; then
    PKG_MANAGER="apt-get"
    CHECK_CMD="dpkg -l"
else
    abort "::: Unsupported distribution: $DIST"
fi

info "::: Uninstalling OrkAudio ... \n"

# backup old config
if [ -d /etc/orkaudio ]; then
    info "::: Backing up old configuration to: ~"
    tar -C /etc/orkaudio/ -czvpf ~/orkaudio-config-$(date +%Y%m%d-%H%M%S).tar.gz .
fi


# uninstall any package
PKGS="orkspeex orkbase orkbasecxx orkaudio"
for PKG in $PKGS; do
    if ${CHECK_CMD} "$PKG"; then
        ${PKG_MANAGER} -y remove "$PKG"
    fi
done

if [[ "$PKG_MANAGER" = "apt-get" ]]; then
    ${PKG_MANAGER} -y autoremove
fi


rm -rf /usr/include/bcg729
rm -rf /usr/lib/pkgconfig/libbcg729.pc
rm -rf /usr/lib/libbcg729.*
rm -rf /usr/lib64/libbcg729.*
rm -rf /usr/lib/libgenerator.*
rm -rf /usr/lib/liborkbase.*
rm -rf /usr/lib/libvoip.*
rm -rf /usr/lib64/libbcg729.*
rm -rf /usr/lib64/pkgconfig/libbcg729.pc
rm -rf /usr/lib/x86_64-linux-gnu/libbcg729.*
rm -rf /usr/lib/x86_64-linux-gnu/pkgconfig/libbcg729.pc
rm -rf /usr/lib/orkaudio
rm -rf /usr/share/Bcg729
rm -rf /usr/sbin/orkaudio
rm -rf /etc/orkaudio
rm -rf /var/log/orkaudio

if command -v chkconfig &> /dev/null && chkconfig orkaudio; then
    chkconfig orkaudio off
    chkconfig --del orkaudio
    test -f /etc/init.d/orkaudio && rm -f /etc/init.d/orkaudio
fi

test -f /etc/supervisor/conf.d/orkaudio.conf && rm -f /etc/supervisor/conf.d/orkaudio.conf

info "::: Finished!\n"