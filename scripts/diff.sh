#!/bin/bash

echo && echo "INFO: Diffing hosts from the last two scans ..."

sendnotif=$1
faraday_workspace=$2

new_hosts_file=out/new_hosts.txt
rm -f $new_hosts_file

redis-cli -h $REDIS_SERVER GET "$faraday_workspace"_last_hosts | jq -r '.[] | .value.name' | sort > out/hosts1.txt
redis-cli -h $REDIS_SERVER GET "$faraday_workspace"_second_last_hosts | jq -r '.[] | .value.name' | sort > out/hosts2.txt
comm -23 hosts1.txt hosts2.txt > $new_hosts_file

if [ -s "$new_hosts_file" ]; then
    echo "INFO: New dicovered hosts saved in $new_hosts_file"
    if [ "$sendnotif" == "1" ]; then
        echo "INFO: Sending notification ..."
        if [ $(uname) == "Linux" ]; then
            sed -i '1s/^/New hosts discovered:\n/' $new_hosts_file
        fi
        if [ $(uname) == "Darwin" ]; then
            sed -i '' '1s/^/New hosts discovered:\n/' $new_hosts_file
        fi
        notify -nc -pc ./notify-config.yaml -i $new_hosts_file --bulk
    fi
else
    echo "INFO: No new hosts detected"
    echo "No new hosts detected" | notify -nc -pc ./notify-config.yaml
fi