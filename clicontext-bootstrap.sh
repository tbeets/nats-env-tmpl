#!/usr/bin/env bash

NATSURL="nats://localhost:4222"

setcontext () {
nats ctx save \
		--server $NATSURL \
		--creds "$(pwd)/vault/.nkeys/creds/NatsOp/$ACCT/$USER.creds" \
	    $CTXNAME
}

setsystemcontext () {
nats ctx save \
		--server $NATSURL \
		--creds "$(pwd)/vault/.nkeys/creds/NatsOp/SYS/System.creds" \
	    $CTXNAME
}


CTXLIST=( 'UserA1' 'UserA2' 'UserB1' 'UserB2' 'UserC1' 'UserC2' )
ACCTLIST=( 'AcctA' 'AcctA' 'AcctB' 'AcctB' 'AcctC' 'AcctC')
USERLIST=( 'UserA1' 'UserA2' 'UserB1' 'UserB2' 'UserC1' 'UserC2' )

for (( i = 0; i < ${#CTXLIST[@]}; ++i )); do
    CTXNAME=${CTXLIST[i]}
    ACCT=${ACCTLIST[i]}
    USER=${USERLIST[i]}
    setcontext
done

CTXNAME="System"
setsystemcontext
