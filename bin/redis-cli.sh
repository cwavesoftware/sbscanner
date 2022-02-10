#!/bin/bash

source ../.env
docker-compose --file ../docker-compose.yml --env-file ../.env run --rm --entrypoint redis-cli scanner -h $REDIS_SERVER $@