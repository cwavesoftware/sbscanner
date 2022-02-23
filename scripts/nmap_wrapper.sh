#!/bin/bash

targetfile=nmap_targets.txt
rm -f $targetfile
cat $1 | jq -r '[.[] | { ip:.ip, port:.ports[0].port}] | group_by(.ip)[] | {ip:.[0].ip, ports: [.[].port]} | .ip + " -p T:" + (.ports | join(","))' | sort > $targetfile

rm -rf out/nmap_report*
echo && echo "INFO: Running nmap ..."
echo "INFO: Target file:" && cat $targetfile

while IFS= read -r target
do
    nmap -sV -Pn -oX out/nmap_report_$(echo $target | cut -d " " -f1).xml $target
done < "$targetfile"
echo "INFO: Results saved to out/nmap_report_*"