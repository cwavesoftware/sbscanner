#!/bin/bash

send_notif=$1
faraday_workspace=$2

echo && echo "INFO: Checking ports ..."
last_host_port_file=out/host_port.txt
rm -f $last_host_port_file
ports_not_allowed_file=out/ports_not_allowed.txt
rm -f $ports_not_allowed_file

faraday-cli service list -w $faraday_workspace -j | jq -r '.[] | [.value.host.ip, .value.port] | join(":")' | sort > $last_host_port_file

while IFS= read -r line
do
    redis-cli -h $REDIS_SERVER DEL $line:fixed
    if [ $(redis-cli -h $REDIS_SERVER --raw EXISTS "$line:allowed") -eq 1 ] && [ $(redis-cli -h $REDIS_SERVER --raw GET "$line:allowed") == "true" ]; then
        echo "$line is allowed"
    else
        echo $line >> $ports_not_allowed_file
    fi
done < "$last_host_port_file"

if [ -s "$ports_not_allowed_file" ]; then
    echo "INFO: Not allowed ports saved into $ports_not_allowed_file:" && cat $ports_not_allowed_file
    new_ports_file=out/new_ports.txt
    comm -23 $ports_not_allowed_file second_last_host_port.txt > $new_ports_file

    echo "INFO: Filtering ports we don't want to be notified about ..."
    cp $new_ports_file $new_ports_file.copy
    rg=$(echo $3 | sed -E 's/,/$|:/pg' | sed -En 's/^/:/pg' | sed -En 's/$/\$/pg' | head -n 1)
    grep -v -E "$rg" $new_ports_file.copy > $new_ports_file

    if [ "$send_notif" == "1" ]; then
        if [ -s "$new_ports_file" ]; then
            # We send notifications only for new ports discovered
            echo "INFO: Sending notification ..."
            if [ $(uname) == "Linux" ]; then
                sed -i '1s/^/New ports discovered:\n/' $new_ports_file
            fi
            if [ $(uname) == "Darwin" ]; then
                sed -i '' '1s/^/New ports discovered:\n/' $new_ports_file
            fi
            notify -nc -pc ./notify-config.yaml -i $new_ports_file --bulk --cl 1000
        else
            echo "No new ports detected" 
            echo "No new ports detected" | notify -nc -pc ./notify-config.yaml
        fi
    else
        echo "Notifications are OFF"
    fi
fi

echo "INFO: Looking for ports that were fixed ..."
fixed_ports_file=out/fixed_ports.txt
comm -23 second_last_host_port.txt $last_host_port_file > $fixed_ports_file
if [ -s "$fixed_ports_file" ]; then
    echo "INFO: Some ports were fixed (closed):" && cat $fixed_ports_file 

    while IFS= read -r line
    do
        redis-cli -h $REDIS_SERVER SET "$line:fixed" true
    done < "$fixed_ports_file"

    if [ "$send_notif" == "1" ]; then
        echo "INFO: Sending notification ..."
        if [ $(uname) == "Linux" ]; then
            sed -i '1s/^/Fixed (closed) ports:\n/' $fixed_ports_file
        fi
        if [ $(uname) == "Darwin" ]; then
            sed -i '' '1s/^/Fixed (closed) ports:\n/' $fixed_ports_file
        fi
        # notify -nc -pc ./notify-config.yaml -i $fixed_ports_file --bulk --cl 1000
    fi
else
    echo "INFO: No ports were fixed"
fi

exit 0
