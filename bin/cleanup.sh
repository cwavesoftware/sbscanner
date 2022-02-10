#!/bin/bash

docker-compose --file ../docker-compose.yml --env-file ../.env run --rm --entrypoint /bin/bash scanner clean_up.sh