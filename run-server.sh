#!/bin/bash

export SCRIPTROOT="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

nats-server --config "$SCRIPTROOT/conf/server.conf"