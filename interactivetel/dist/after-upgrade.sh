# restart orkaudio
if pgrep orkaudio >/dev/null 2>&1; then
  command -v supervisorctl &>/dev/null && {
    if supervisorctl status orkaudio >/dev/null 2>&1; then
      supervisorctl restart orkaudio || :
    fi
  }
fi
