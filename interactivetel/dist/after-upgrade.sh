
if pgrep supervisor > /dev/null 2>&1; then
    if pgrep orkaudio > /dev/null 2>&1; then
        test -x /usr/local/totaltrack/bin/supervisorctl && {
            echo "Restarting OrkAudio"
            /usr/local/totaltrack/bin/supervisorctl restart orkaudio || :
        }
    fi
fi