# nats-lab

## Configure operator and system account

```bash
source ./setnscenv.sh
nsc add operator "NatsOp"
# location of NatsOp credential placed in server's operator configuration 
nsc edit operator --service-url "nats://localhost:4222"
nsc edit operator --account-jwt-server-url "nats://localhost:4222"
nsc add account --name SYS
nsc add user --account SYS --name System
nsc edit operator --system-account "<public NKEY of SYS>"
# public NKEY of SYS placed in server's system_account configuration
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
