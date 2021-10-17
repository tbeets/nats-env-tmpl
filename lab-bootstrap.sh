#/bin/bash

source ./setnscenv.sh

# EDIT THESE
SERVERNAME="nats-lab"
NATSHOST="localhost"
NATSPORT="4222"
NATSMONITORPORT="8222"
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

SYSTEMACCTPUBNKEY=`cat ${NSC_HOME}/nats/${OPERATORNAME}/accounts/${SYSTEMACCTNAME}/${SYSTEMACCTNAME}.jwt | ./util/decodejwt.sh | jq -r '.["sub"] | select( . != null )'`

nsc edit operator --system-account ${SYSTEMACCTPUBNKEY} 

# location of NatsOp credential placed in server's operator configuration
# public NKEY of SYS placed in server's system_account configuration

echo -e "\nWriting server configuration:\n"
tee ./conf/serverpki.conf <<EOF
server_name: ${SERVERNAME}
client_advertise: "${NATSHOST}:${NATSPORT}"
port: ${NATSPORT}
monitor_port: ${NATSMONITORPORT} 

operator: "/vault/nats/${OPERATORNAME}/${OPERATORNAME}.jwt"
system_account: "${SYSTEMACCTPUBNKEY}"

jetstream {
  store_dir: /state
}

resolver: {
  type: full
  dir: '/state/.jwt'
  allow_delete: true
  interval: "2m"
  limit: 1000
}
EOF
