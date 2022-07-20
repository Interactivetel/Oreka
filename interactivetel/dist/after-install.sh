echo "Tunning the system ..."

# disable selinux
test -f /etc/selinux/config && {
  printf "\nDisabling SELINUX\n"
  sed -i "s/SELINUX=[a-z].*/SELINUX=disabled/" /etc/selinux/config
}

# set the max OS receive buffer size for all types of connections.
printf "Setting the network receive buffer max size to 16Mb\n"
/sbin/sysctl -w net.core.rmem_max=16777216 >/dev/null
sed -i "/net.core.rmem_max/d" /etc/sysctl.conf
echo "net.core.rmem_max = 16777216" | tee -a /etc/sysctl.conf >/dev/null

# clean old stuff
sed -i "/Interactivetel/d" /etc/sysctl.conf
sed -i "/Inteactivetel/d" /etc/sysctl.conf

ldconfig
