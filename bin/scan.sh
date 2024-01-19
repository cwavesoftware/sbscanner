#!/bin/bash

docker compose --file ../docker-compose.yml --env-file ../.env run scanner $@
docker compose --file ../docker-compose.yml down redis