# nats-lab

Instant setup of a NATS lab environment with JetStream enabled and Decentralized JWT Authentication/Authorization

## Pre-requisites
* linux
* docker (if running server)
* git
* jq
* nats cli tool
* nsc cli tool

## Bootstrap lab

```bash
git clone git@github.com:tbeets/nats-env-tmpl.git <yourprj>; cd <yourprj>
# edit defaults in lab-bootstrap.sh as desired
./lab-bootstrap.sh; ./clicontext-bootstrap.sh
./run-serverpki.sh # assuming run your new lab server configuration
source ./setnscenv.sh; nsc push --all
nats --context System server list
```

## Decentralized JWT Authentication/Authorization

### Accounts
* SYS
* AcctA
* AcctB
* AcctC

### Users (each with NATS CLI Context)
* System
* UserA1, UserA2
* UserB1, UserB2
* UserC1, UserC2
