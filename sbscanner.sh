#!/bin/bash

if which masscan && which faraday-cli; then
    echo "Tools installed, great"
else 
    echo "Some tools were not found, make sure it's installed and available in PATH"
    exit 1
fi

if [ "$#" -lt 3 ]; then
    echo "Usage: bash $0 <ips_input_file> <masscan_rate> <ports>"
    exit 1
fi

echo "the Following IP addresses/ranges will be scanned:"
cat $1

mkdir out 2>/dev/null
outfile=out/masscan_report_`date +%s%3N`.xml

masscan --rate $2 -iL $1 -p$3 -oX $outfile

if [ ! -f $outfile ]; then
    echo "Couln't find the scan report $outfile"
    exit 1
fi

source .env && faraday-cli auth -f $FARADAY_URL -u $FARADAY_USER -p $FARADAY_PASSWORD
if [ $? -gt 0 ]; then
    echo "Couldn't authenticate to faraday server"
    exit 1
fi
faraday-cli workspace select last_scan && faraday-cli tool report $outfile
exit $?