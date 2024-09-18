#!/bin/bash
check_ips_by_earliest_access () {
    if [[ -z "$1" ]]; then
        echo "Usage: check_ips_by_earliest_access <logfile>"
        return 1
    fi

    local logfile="$1"

    echo "Checking Database Accesses - Earliest Access by IP"
    jq -r 'if (.t."$date" and .attr.remote) then [.t."$date", (.attr.remote | split(":")[0])] | @tsv else empty end' "$logfile" 2>/dev/null |
    awk '{if (!($2 in ip) || $1 < ip[$2]) ip[$2]=$1} END {for (i in ip) print ip[i], i}' |
    sort -r
}

check_ips_by_access_count() {
    if [[ -z "$1" ]]; then
        echo "Usage: check_ips_by_access_count <logfile>"
        return 1
    fi

    local logfile="$1"

    echo "Checking Database Accesses - Access Count by IP"
    jq -r '.attr.remote' "$logfile" 2>/dev/null | 
    grep -v 'null' | 
    awk -F':' '{print $1}' | 
    sort | 
    uniq -c | 
    sort -r
}

check_users_access_by_ips() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: check_users_access_by_ips <logfile> <ip1> [ip2] [ip3] ..."
        return 1
    fi

    local logfile="$1"
    shift
    local ips=("$@")
    echo "Checking Database Accesses - Users Accessed by IPs"

    jq -r --arg ips "${ips[*]}" 'select(.attr.remote |
    tostring | split(":")[0] | IN($ips | split(" ")[])) | 
    .attr.principalName' "$logfile" | grep -v '^null$' | sort | uniq
}


