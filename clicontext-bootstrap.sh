#!/usr/bin/env bash

NATSURL=`cat ./conf/env.json | jq -r .NATSURL`
OPERATORNAME=`cat ./conf/env.json | jq -r .OPERATORNAME`
SYSTEMACCTNAME=`cat ./conf/env.json | jq -r .SYSTEMACCTNAME`
SYSTEMUSERNAME=`cat ./conf/env.json | jq -r .SYSTEMUSERNAME`

setcontext () {
nats ctx save \
		--server $NATSURL \
		--creds "$(pwd)/vault/.nkeys/creds/$OPERATORNAME/$ACCT/$USER.creds" \
	    $CTXNAME
}

CTXLIST=( 'System' 'UserA1' 'UserA2' 'UserB1' 'UserB2' 'UserC1' 'UserC2' )
ACCTLIST=( $SYSTEMACCTNAME 'AcctA' 'AcctA' 'AcctB' 'AcctB' 'AcctC' 'AcctC')
USERLIST=( $SYSTEMUSERNAME 'UserA1' 'UserA2' 'UserB1' 'UserB2' 'UserC1' 'UserC2' )

for (( i = 0; i < ${#CTXLIST[@]}; ++i )); do
    CTXNAME=${CTXLIST[i]}
    ACCT=${ACCTLIST[i]}
    USER=${USERLIST[i]}
    setcontext
done
