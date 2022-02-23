#!/bin/bash

faraday_workspace=last_scan

echo && echo "INFO: Checking ports ..."
tmp=host_port.txt
rm -f $tmp
outfile=ports_not_allowed.txt
rm -f $outfile
faraday-cli service list -w $faraday_workspace -j | jq -r '.[] | [.value.host.ip, .value.port] | join(":")' | sort > $tmp

while IFS= read -r line
do
    redis-cli -h $REDIS_SERVER DEL $line:fixed
    if [ $(redis-cli -h $REDIS_SERVER --raw EXISTS "$line:allowed") -eq 1 ] && [ $(redis-cli -h $REDIS_SERVER --raw GET "$line:allowed") == "true" ]; then
        echo "$line is allowed"
    else
        echo $line >> $outfile
    fi
done < "$tmp"

if [ -s "$outfile" ]; then
    echo "INFO: Not allowed ports saved into $outfile:" && cat $outfile
    if [ "$1" == "1" ]; then
        echo "INFO: Sending notification ..."
        if [ $(uname) == "Linux" ]; then
            sed -i '1s/^/Not allowed ports:\n/' $outfile
        fi
        if [ $(uname) == "Darwin" ]; then
            sed -i '' '1s/^/Not allowed ports:\n/' $outfile
        fi
        notify -pc ./notify-config.yaml -i $outfile --bulk
    fi
fi

echo "INFO: Looking for ports that were fixed ..."
fixed_ports=fixed_ports.txt
mv $tmp ports1.txt
comm -23 ports2.txt ports1.txt > $fixed_ports
if [ -s "$fixed_ports" ]; then
    echo "INFO: Some ports were fixed (closed):" && cat $fixed_ports 

    while IFS= read -r line
    do
        redis-cli -h $REDIS_SERVER SET "$line:fixed" true
    done < "$fixed_ports"

    if [ "$1" == "1" ]; then
        echo "INFO: Sending notification ..."
        if [ $(uname) == "Linux" ]; then
            sed -i '1s/^/Fixed (closed) ports:\n/' $fixed_ports
        fi
        if [ $(uname) == "Darwin" ]; then
            sed -i '' '1s/^/Fixed (closed) ports:\n/' $fixed_ports
        fi
        notify -pc ./notify-config.yaml -i $fixed_ports --bulk
    fi
else
    echo "INFO: No ports were fixed"
fi

exit 0
