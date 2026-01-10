# Redirecting output to console
# Mainly for monitoring long-running processes like image fetching and unpacking

type getarg > /dev/null 2>&1 || . /lib/dracut-lib.sh

bootc_warn_output() {
    "$@" 2>&1 | vwarn
}

check_bootc_quiet() {
    if getargbool 0 bootc.quiet; then
        bootc_long_running_process=
    else
        bootc_long_running_process=bootc_warn_output
    fi
}
