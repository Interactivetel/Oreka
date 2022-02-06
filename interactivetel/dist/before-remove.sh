
# remove custom config from sysctl.conf
test -f /etc/sysctl.conf && {
    sed -i "/## Interactivetel/d" /etc/sysctl.conf
    sed -i "/net.core.rmem_max/d" /etc/sysctl.conf
} 