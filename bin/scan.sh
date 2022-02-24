#!/bin/bash

docker-compose --file ../docker-compose.yml --env-file ../.env run --rm scanner $@
docker-compose down