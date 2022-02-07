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
outfile=out/masscan_report_`date +%s%3N`.json

echo "INFO: Running masscan ..."
# sudo masscan --rate $2 -iL $1 -p T:$3 -oX $outfile
sudo masscan --rate $2 -iL $1 -p T:$3 -oJ $outfile
if [ $? -gt 0 ]; then
    echo "ERROR: masscan raised an error"
    exit 1
fi

if [ ! -s "$outfile" ]; then
    echo "ERROR: masscan report file $outfile doesn't exist or is empty. Exiting ..."
    exit 1
fi
echo "INFO: Results saved to $outfile"

bash nmap_wrapper.sh $outfile

echo "INFO: Importing nmap results into faraday ..."
faraday-cli auth -f $FARADAY_URL -u $FARADAY_USER -p $FARADAY_PASSWORD
if [ $? -gt 0 ]; then
    echo "ERROR: Couldn't authenticate to faraday server"
    exit 1
fi

# Delete last scan from faraday and replace it with most recent scan
faraday-cli workspace delete $faraday_workspace
faraday-cli workspace create $faraday_workspace
faraday-cli workspace select $faraday_workspace
while IFS= read -r report
do
    faraday-cli tool report $report
done < <(ls -al out/nmap_report* | cut -d " " -f10)

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
redis-cli SET last_services "$(echo $services)" && echo "INFO: last_services saved in redis"

echo "Diffing hosts from the last two scans ..."
new_hosts_file=new_hosts.txt
rm -f $new_hosts_file
redis-cli GET last_hosts | jq -r '.[] | .value.name' | sort > hosts1.txt
redis-cli GET second_last_hosts | jq -r '.[] | .value.name' | sort > hosts2.txt
comm -23 hosts1.txt hosts2.txt > $new_hosts_file
if [ -s "$new_hosts_file" ]; then
    echo "INFO: New dicovered hosts saved in $new_hosts_file"
    if [ "$sendnotif" == "1" ]; then
        echo "INFO: Sending notification ..."
        sed -i '1s/^/New hosts discovered:\n/' $new_hosts_file
        notify -pc ./notify-config.yaml -i $new_hosts_file --bulk
    fi
else
    echo "INFO: No new hosts detected"
fi

bash check_ports.sh $sendnotif

exit $?