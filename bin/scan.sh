#!/bin/bash

# need to check if faraday is already running from other jobs
faraday_hostname=$(cat ../docker-compose.yml | yq '.services.faraday.hostname')
[[ -z $faraday_hostname ]] && echo "could not get faraday hostname, exiting" && exit -1

net=$(cat ../docker-compose.yml | yq '.networks.default.name')
[[ -z $net ]] && echo "could not get network name, exiting" && exit -2

running=$(sudo docker network inspect $net |
	jq '.[] | .Containers | map(.Name)[]' | sed 's/"//g' |
	xargs -I {} bash -c "sudo docker inspect {} | jq '.[0] | .Config.Hostname'" |
	sed 's/"//g' | grep faraday.server)
echo "$faraday_hostname running: $(if [[ $faraday_hostname == $running ]]; then echo true; else echo false; fi)"

[[ $faraday_hostname != $running ]] && docker compose --file ../docker-compose.yml --env-file ../.env up -d faraday
docker compose --file ../docker-compose.yml --env-file ../.env run scanner $@
docker compose --file ../docker-compose.yml down redis
