#!/bin/bash

source ./setnscenv.sh

# EDIT THESE 
NATSHOST="localhost"
NATSPORT="4222"
OPERATORNAME="NatsOp"
SYSTEMACCTNAME="SYS"
SYSTEMUSERNAME="System"
############

OPERATORSERVICEURL="nats://${NATSHOST}:${NATSPORT}"
OPERATORJWTSERVERURL="nats://${NATSHOST}:${NATSPORT}"

nsc add operator ${OPERATORNAME} 
nsc edit operator --service-url ${OPERATORSERVICEURL} --account-jwt-server-url ${OPERATORJWTSERVERURL} 
nsc add account --name ${SYSTEMACCTNAME} 
nsc add user --account ${SYSTEMACCTNAME} --name ${SYSTEMUSERNAME}

SYSTEMACCTPUBNKEY=`cat ${NSC_HOME}/nats/${OPERATORNAME}/${OPERATORNAME}.jwt | ./util/decodejwt.sh | jq -r '.["nats"] | select( . != null ) | .["system_account"]'`
echo "got: ${SYSTEMACCTPUBNKEY}"

nsc edit operator --system-account ${SYSTEMACCTPUBNKEY} 

# location of NatsOp credential placed in server's operator configuration
# public NKEY of SYS placed in server's system_account configuration

tee -a ./conf/serverpki.conf <<EOF
blah blah blah
EOF
