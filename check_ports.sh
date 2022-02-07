#!/bin/bash

echo "INFO: Checking ports ..."
# ports=$(redis-cli get last_services | jq '[.[] | {ip:.value.host.ip, port:.value.port}]' | jq 'group_by(.ip)[] | {(.[0].ip): [{port: .[].port, allowed: false}]}')
# if [ `redis-cli --raw EXISTS last_ports` -gt 0 ]; then
#     redis-cli DEL second_last_ports
#     redis-cli COPY last_ports second_last_ports
#     echo "INFO: Redis last_ports copied to second_last_ports"
# else
#     echo "INFO: last_ports not found in redis"
# fi
# redis-cli SET last_ports "$(echo $ports)" && echo "INFO: last_ports saved in redis"
tmp=host_port.txt
outfile=ports_not_allowed.txt
rm -f $outfile @>/dev/null
redis-cli GET last_services | jq -r '.[] | [.value.host.ip, .value.port] | join(":")' | sort > $tmp

while IFS= read -r line
do
    if [ $(redis-cli --raw EXISTS "$line:allowed") -eq 1 ] && [ $(redis-cli --raw GET "$line:allowed") == "true" ]; then
        echo "$line is allowed"
    else
        echo $line >> $outfile
    fi
done < "$tmp"

echo "INFO: Not allowed ports saved into $outfile"

exit 0
