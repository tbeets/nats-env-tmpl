#!/bin/bash

source ./setnscenv.sh

OPERATORNAME=`cat ./conf/env.json | jq -r .OPERATORNAME`

getpubnkey () {
  PUBNKEY=`cat ${NSC_HOME}/nats/${OPERATORNAME}/accounts/${ACCTNAME}/${ACCTNAME}.jwt | ./util/decodejwt.sh | jq -r '.["sub"] | select( . != null )'`
}

# Account Refs
ACCTA="AcctA"
ACCTNAME=$ACCTA; getpubnkey
ACCTAPUBKEY=$PUBNKEY

ACCTB="AcctB"
ACCTNAME=$ACCTB; getpubnkey
ACCTBPUBKEY=$PUBNKEY

ACCTC="AcctC"
ACCTNAME=$ACCTC; getpubnkey
ACCTCPUBKEY=$PUBNKEY

#### Exports ####

# AcctA


# AcctB


# AcctC

#### Imports ####

# AcctA


# AcctB


# AcctC

# DON'T FORGET TO NSC PUSH --ALL WHEN READY