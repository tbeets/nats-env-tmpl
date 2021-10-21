# nats-lab

## Pre-requisites
* linux
* docker
* git
* jq
* nats cli tool
* nsc cli tool

## Bootstrap

```bash
git clone git@github.com:tbeets/nats-env-tmpl.git <yourprj>; cd <yourprj>
./lab-bootstrap.sh; ./clicontext-bootstrap.sh
./run-serverpki.sh; source ./setnscenv.sh; nsc push --all
nats --context System server list
```

