#!/bin/bash

redis-cli -h $REDIS_SERVER DEL last_hosts
redis-cli -h $REDIS_SERVER DEL second_last_hosts

echo "Done"
