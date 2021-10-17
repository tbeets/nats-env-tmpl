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
git clone git@github.com:tbeets/nats-lab-tmpl.git <YOUR PROJECT DIRECTORY>
cd <YOUR PROJECT DIRECTORY>
./lab-bootstrap.sh
./run-serverpki.sh
source ./setnscenv.sh
nsc push --all
```

## Configure base accounts and users

```bash
source ./setnscenv.sh
nsc add account "AcctA"
nsc edit account --name "AcctA" --js-disk-storage=-1 --js-mem-storage=-1 --js-streams=-1 --js-consumer=-1
nsc add user --name "UserA1" --account "AcctA"
nsc add user --name "UserA2" --account "AcctA"

nsc add account "AcctB"
nsc edit account --name "AcctB" --js-disk-storage=-1 --js-mem-storage=-1 --js-streams=-1 --js-consumer=-1
nsc add user --name "UserB1" --account "AcctB"
nsc add user --name "UserB2" --account "AcctB"

nsc add account "AcctC"
nsc edit account --name "AcctC" --js-disk-storage=-1 --js-mem-storage=-1 --js-streams=-1 --js-consumer=-1
nsc add user --name "UserC1" --account "AcctC"
nsc add user --name "UserC2" --account "AcctC"
```
