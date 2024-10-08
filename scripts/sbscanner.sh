#!/bin/bash

echo "INFO: Checking for necessary tools ..."
if which masscan && which faraday-cli && which redis-cli && which jq; then
  echo "INFO: Tools installed, great"
else
  echo "ERROR: Some tools were not found, make sure it's installed and available in PATH"
  exit 1
fi

if [ "$#" -lt 5 ]; then
  echo "Usage: bash $0 <ips_input_file> <masscan_rate> <ports> <faraday_workspace> <make_diff> [ports_to_skip_notifications]"
  exit 1
fi

faraday_workspace=$4
make_diff=$5
ports_to_skip_notifications=$6
echo "Using faraday workspace $faraday_workspace"

echo "INFO: The Following IP addresses/ranges will be scanned:"
cat targets/$1

mkdir out 2>/dev/null
outfile=out/masscan_report_$(date +%s%3N).json

echo "INFO: Running masscan ..."
masscan --rate $2 -iL targets/$1 -p T:$3 -oJ $outfile
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

echo && echo "INFO: Importing nmap results into faraday ..."
faraday-cli auth -f $FARADAY_URL -u $FARADAY_USER -p "$FARADAY_PASSWORD"
if [ $? -gt 0 ]; then
  echo "ERROR: Couldn't authenticate to faraday server"
  exit 1
fi

if [ "$make_diff" == "true" ]; then
  faraday-cli service list -w $faraday_workspace -j | jq -r '.[] | [.value.host.ip, .value.port] | join(":")' | sort >second_last_host_port.txt
  # Delete last scan from faraday and replace it with most recent scan
  faraday-cli workspace delete $faraday_workspace
fi

faraday-cli workspace create $faraday_workspace
faraday-cli workspace select $faraday_workspace

while IFS= read -r report; do
  faraday-cli tool report $report
done < <(ls -al out/nmap_report* | rev | cut -d " " -f1 | rev)

hosts=$(faraday-cli host list -w $faraday_workspace -j)

if [ "$make_diff" == "true" ]; then
  if [ $(redis-cli -h $REDIS_SERVER --raw EXISTS "$faraday_workspace"_last_hosts) -gt 0 ]; then
    sendnotif=1
    redis-cli -h $REDIS_SERVER DEL "$faraday_workspace"_second_last_hosts
    redis-cli -h $REDIS_SERVER COPY "$faraday_workspace"_last_hosts "$faraday_workspace"_second_last_hosts
    echo "INFO: Redis $(echo $faraday_workspace)_last_hosts copied to $(echo $faraday_workspace)_second_last_hosts"
  else
    echo "INFO: $(echo $faraday_workspace)_last_hosts not found in redis"
  fi
else
  echo "make_diff = $make_diff, we don't compare with previous scan"
fi

sanitized_hosts=$(echo "$hosts" | jq -c '.')
echo "INFO-mpetrea sanitized_hosts var -->  $sanitized_hosts "
if [ "$make_diff" == "true" ]; then
  redis-cli -h $REDIS_SERVER SET $(echo -n $faraday_workspace)_last_hosts "$(echo -n $hosts)" &&
  #redis-cli -h $REDIS_SERVER SET $(echo -n $faraday_workspace)_last_hosts "$sanitized_hosts" &&

    echo "INFO: $(echo -n $faraday_workspace)_last_hosts saved in redis" &&
    bash diff.sh $sendnotif $faraday_workspace &&
    bash check_ports.sh $sendnotif $faraday_workspace $ports_to_skip_notifications
else # is probably on demand
  echo $hosts >./out/hosts.json
  rm ./out/msg.txt
  touch ./out/msg.txt
  while read -r ip; do
    [[ -z $ip ]] && continue
    hjson=$(cat ./out/hosts.json | jq --arg ip "$ip" '.[] | if .value.name==$ip then .value else empty end')
    if [[ -z $hjson ]]; then
      echo "no scan results for $ip" >>./out/msg.txt
      continue
    fi
    hid=$(echo $hjson | jq .id)
    echo " ----> mpetrea hid = $hid "
    hname=$(echo $hjson | jq '.hostnames[0]' | sed 's/"//g')
    echo " ----> mpetrea hname = $hname "
    [[ "$hname" == "null" ]] && hname=$(echo $hjson | jq '.name' | sed 's/"//g')
    portsss=$(echo hjson | jq '.service_summaries')
    #echo "port scan for $hname completed: $(echo hjson | jq '.service_summaries')" >>./out/msg.txt
    echo "---->mpetrea --> port scan for $hname completed: $portsss " >>./out/msg.txt
  done <targets/$1
  ls -al ./out/msg.txt 
  echo "cat --> ./out/msg.txt" 
  cat ./out/msg.txt
  [[ -s "./out/msg.txt" ]] && notify -nc -pc ./notify-config.yaml -i ./out/msg.txt --bulk
fi
