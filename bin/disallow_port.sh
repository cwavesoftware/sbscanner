#!/bin/bash

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <ip> <port>"
    exit 1
fi
bash redis-cli.sh SET $1:$2:allowed false