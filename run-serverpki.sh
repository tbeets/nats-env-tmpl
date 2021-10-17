#!/bin/bash

docker run -it \
--mount type=bind,source="$(pwd)"/conf,target=/conf \
--mount type=bind,source="$(pwd)"/vault,target=/vault \
--mount type=bind,source="$(pwd)"/state,target=/state \
-p 4222:4222 \
-p 8222:8222 \
nats:latest --config /conf/serverpki.conf
