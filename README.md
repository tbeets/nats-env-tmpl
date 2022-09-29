# nats-lab

Instant setup of a NATS lab environment with JetStream enabled, optional docker, optional PKI (JWT or mTLS)

## Pre-requisites
* linux
* docker (if running containerized NATS server)
* git
* jq
* mkcert (if configuring mTLS auth only)
* nats cli tool
* nsc cli tool (if running PKI environment)
* nats-server executable in path (if running non-docker lab)

## Configure Lab
Edit `lab-bootstrap.sh` if you want to change any defaults, such as:

* PKI - If "true" the environment will use JWT-based Accounts and Users  (default "false")
* PKI - If "mtls" the environment will use mTLS-based Auth with SAN map to Users (and user's account)  
* DOCKER - If "true" the `run-server.sh` script will docker run the `nats:latest` container  (default "false")

## Bootstrap Lab 

```bash
git clone git@github.com:tbeets/nats-env-tmpl.git <yourprj>; cd <yourprj>

# edit lab-bootstrap.sh or use defaults
./lab-bootstrap.sh  # Generate environment
./clicontext-bootstrap.sh  # Generate/update client contexts
./run-server.sh # run your new lab server 

# Only if PKI (JWT) configured must push Account JWTs to running server
source ./setnscenv.sh; nsc push --all

# With system account privileges, list servers
nats --context System server list
```

## Account-based Authentication/Authorization

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
