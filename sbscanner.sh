#!/bin/bash

faraday_workspace=last_scan

source .env

echo "INFO: Checking for necessary tools ..."
if which masscan && which faraday-cli && which redis-cli && which jq && which notify; then
    echo "INFO: Tools installed, great"
else 
    echo "ERROR: Some tools were not found, make sure it's installed and available in PATH"
    exit 1
fi

if [ "$#" -lt 3 ]; then
    echo "Usage: bash $0 <ips_input_file> <masscan_rate> <ports>"
    exit 1
fi

echo "INFO: The Following IP addresses/ranges will be scanned:"
cat $1

mkdir out 2>/dev/null
outfile=out/masscan_report_`date +%s%3N`.xml

sudo masscan --rate $2 -iL $1 -p$3 -oX $outfile
if [ ! -s "$outfile" ]; then
    echo "ERROR: masscan report file $outfile doesn't exist or is empty. Exiting ..."
    exit 1
fi

faraday-cli auth -f $FARADAY_URL -u $FARADAY_USER -p $FARADAY_PASSWORD
if [ $? -gt 0 ]; then
    echo "ERROR: Couldn't authenticate to faraday server"
    exit 1
fi
# Delete last scan from faraday and replace it with most recent scan
faraday-cli workspace delete $faraday_workspace
faraday-cli workspace create $faraday_workspace
faraday-cli workspace select $faraday_workspace && faraday-cli tool report $outfile

hosts=`faraday-cli host list -w $faraday_workspace -j`
services=`faraday-cli service list -w $faraday_workspace -j`

# echo "Last scan:"
# echo $scan | jq '.'

if [ `redis-cli --raw EXISTS last_hosts` -gt 0 ]; then
    sendnotif=1
    redis-cli DEL second_last_hosts
    redis-cli COPY last_hosts second_last_hosts
    echo "INFO: Redis last_hosts copied to second_last_hosts"
else
    echo "INFO: last_hosts not found in redis"
fi
redis-cli SET last_hosts "$(echo $hosts)" && echo "INFO: last_hosts saved in redis"

if [ `redis-cli --raw EXISTS last_services` -gt 0 ]; then
    redis-cli DEL second_last_services
    redis-cli COPY last_services second_last_services
    echo "INFO: Redis last_services copied to second_last_services"
else
    echo "INFO: last_services not found in redis"
fi
redis-cli SET last_services "$(echo $services)" && echo "INFO: last_hosts saved in redis"

echo "Diffing the two last scans ..."
new_hosts_file=new_hosts.txt
rm -f $new_hosts_file 2>/dev/null
redis-cli GET last_scan | jq '.[] | .value.name' | sort > hosts1.txt
# redis-cli get last_services | jq 'keys | .[0]' | sort > services1.txt
redis-cli GET second_last_scan | jq '.[] | .value.name' | sort > hosts2.txt
# redis-cli get second_last_services | jq 'keys | .[0]' | sort > services2.txt

comm -23 hosts1.txt hosts2.txt > $new_hosts_file
sed -i 's/\"//g' $new_hosts_file

if [ -s "$new_hosts_file" ]; then
    echo "INFO: New hosts in $new_hosts_file"
    if [ "$sendnotif" == "1" ]; then
        echo "INFO: Sending notification ..."
        tmp=$(cat $new_hosts_file) && echo "New hosts discovered" > $new_hosts_file && echo $tmp >> $new_hosts_file
        notify -pc ./notify-config.yaml -i $new_hosts_file
    fi
else
    echo "INFO: No new hosts detected"
fi

echo "INFO: Checking ports ..."
ports=$(redis-cli get last_services | jq '[.[] | {ip:.value.host.ip, port:.value.port}]' | jq 'group_by(.ip)[] | {(.[0].ip): [{port: .[].port, allowed: false}]}')
if [ `redis-cli --raw EXISTS last_ports` -gt 0 ]; then
    redis-cli DEL second_last_ports
    redis-cli COPY last_ports second_last_ports
    echo "INFO: Redis last_ports copied to second_last_ports"
else
    echo "INFO: last_ports not found in redis"
fi
redis-cli SET last_ports "$(echo $ports)" && echo "INFO: last_ports saved in redis"

exit $?