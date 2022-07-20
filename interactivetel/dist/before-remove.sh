# stop orkaudio
if pgrep orkaudio >/dev/null 2>&1; then
  command -v supervisorctl &>/dev/null && {
    if supervisorctl status orkaudio >/dev/null 2>&1; then
      supervisorctl stop orkaudio || :
    fi
  }

  if pgrep orkaudio >/dev/null 2>&1; then
    killall orkaudio || :
    sleep 3
  fi

  if pgrep orkaudio >/dev/null 2>&1; then
    killall -9 orkaudio || :
  fi

fi

# remove custom config from sysctl.conf
test -f /etc/sysctl.conf && {
  sed -i "/## Interactivetel/d" /etc/sysctl.conf
  sed -i "/net.core.rmem_max/d" /etc/sysctl.conf
}
