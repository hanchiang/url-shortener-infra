#! /bin/bash

set -e

source ./helper/timer.sh

wait_for_dns_propagation () {
    domain=$1
    ip_address=$2

    if [ -z "$domain" ]
    then
        echo "domain is required"
        return 1
    fi
    if [ -z "$ip_address" ]
    then
        echo "ip address is required"
        return 1
    fi

    echo "Checking DNS for domain: $domain, ip address: $ip_address"

    local seconds_to_wait=120

    start=$(date +%s)
    time_elapsed=$(get_time_elapsed $start | tail -n 1)

    while [ "$time_elapsed" -lt $seconds_to_wait ];
    do
        arr=($(nslookup $domain | grep Address | cut -d ' ' -f 2 | grep "^[0-9]"))

        if [ "$?" -ne 0 ]
        then
            echo "DNS record for $domain is not found. Waiting."
            sleep 10
            continue
        fi

        for ip in "${arr[@]}"
        do
            if [ "$ip" == $ip_address ]
            then   
                echo "DNS for $domain is propagated with ip $ip_address"
                return 0
            else
                echo "found ip address $ip, which is not our target ip address $ip_address"
            fi
        done
        echo "Waiting for DNS to be propagated"
        sleep 10
        time_elapsed=$(get_time_elapsed $start | tail -n 1)
    done

    echo "unable to find dns for $ip_address. Check the DNS settings"
    return 1
}