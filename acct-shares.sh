#!/bin/bash

source ./setnscenv.sh

setcontext () {
nats ctx save \
		--server $NATSURL \
		--creds "$(pwd)/vault/.nkeys/creds/NatsOp/$ACCT/$USER.creds" \
	    $CTXNAME
}

# Account Refs
ACCTA="AcctA"
nats/NatsOp/accounts/$ACCTA
ACCTAPUBKEY="AA5SJ572OYFDF4IJL7AYE52CTV3A4WRI7N374WID7RCITVMIPNNYOGKU"

ACCTB="AcctB"
ACCTBPUBKEY="AAM7Y6G2OPECWTBXDC4J33ZPDF34Y7YP2KXMUC4ALCUXJ3N3CK5DGRB4"

ACCTC="AcctC"
ACCTCPUBKEY="ADWO7VPBKTP74RS3N5PQTC6W7ANOV4S2HHYSEECN35KHFDNFJ644KCCV"

#### Exports ####

# AcctA


# AcctB


# AcctC

#### Imports ####

# AcctA


# AcctB


# AcctC