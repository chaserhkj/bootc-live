# Redirecting output to console
# Mainly for monitoring long-running processes like image fetching and unpacking
bootc_redirect_to_console() {
    "$@" 2>&1 | tee /dev/console
}

check_bootc_quiet() {
    if getargbool 0 bootc.quiet; then
        bootc_long_running_process=
    else
        bootc_long_running_process=bootc_redirect_to_console
    fi
}
