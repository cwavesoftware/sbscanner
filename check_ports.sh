#!/bin/bash

echo "INFO: Checking ports ..."
tmp=host_port.txt
rm -f $tmp
outfile=ports_not_allowed.txt
rm -f $outfile
redis-cli GET last_services | jq -r '.[] | [.value.host.ip, .value.port] | join(":")' | sort > $tmp

while IFS= read -r line
do
    redis-cli DEL $line:fixed
    if [ $(redis-cli --raw EXISTS "$line:allowed") -eq 1 ] && [ $(redis-cli --raw GET "$line:allowed") == "true" ]; then
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
            sed -i '1s/^/Not allowed ports:\n/' $new_hosts_file
        fi
        if [ $(uname) == "Darwin" ]; then
            sed -i '' '1s/^/Not allowed ports:\n/' $new_hosts_file
        fi
        notify -pc ./notify-config.yaml -i $outfile --bulk
    fi
fi

echo "INFO: Looking for ports that were fixed ..."
fixed_ports=fixed_ports.txt
mv $tmp ports1.txt
redis-cli GET second_last_services | jq -r '.[] | [.value.host.ip, .value.port] | join(":")' | sort > ports2.txt
comm -23 ports2.txt ports1.txt > $fixed_ports
if [ -s "$fixed_ports" ]; then
    echo "INFO: Some ports were fixed (closed):" && cat $fixed_ports 

    while IFS= read -r line
    do
        redis-cli SET "$line:fixed" true
    done < "$fixed_ports"

    if [ "$1" == "1" ]; then
        echo "INFO: Sending notification ..."
        if [ $(uname) == "Linux" ]; then
            sed -i '1s/^/Fixed (closed) ports:\n/' $new_hosts_file
        fi
        if [ $(uname) == "Darwin" ]; then
            sed -i '' '1s/^/Fixed (closed) ports:\n/' $new_hosts_file
        fi
        notify -pc ./notify-config.yaml -i $fixed_ports --bulk
    fi
else
    echo "INFO: No ports were fixed"
fi

exit 0
