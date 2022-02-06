#!/bin/bash

redis-cli DEL last_hosts
redis-cli DEL second_last_hosts
redis-cli DEL last_services
redis-cli DEL second_last_services
redis-cli DEL last_ports
redis-cli DEL second_last_ports

echo "Done"
