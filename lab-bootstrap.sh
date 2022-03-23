#/bin/bash

source ./setnscenv.sh

# EDIT THESE
PKI="false"
DOCKER="false"
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

if [ "$DOCKER" = "true" ]; then
  DIRPREFIX=""
else
  DIRPREFIX="$(pwd)"
fi

if [ "$PKI" = "true" ]; then
  nsc add operator ${OPERATORNAME} 
  nsc edit operator --service-url ${OPERATORSERVICEURL} --account-jwt-server-url ${OPERATORJWTSERVERURL} 
  nsc add account --name ${SYSTEMACCTNAME} 
  nsc add user --account ${SYSTEMACCTNAME} --name ${SYSTEMUSERNAME}

  SYSTEMACCTPUBNKEY=`cat ${NSC_HOME}/nats/${OPERATORNAME}/accounts/${SYSTEMACCTNAME}/${SYSTEMACCTNAME}.jwt | ./util/decodejwt.sh | jq -r '.["sub"] | select( . != null )'`

  nsc edit operator --system-account ${SYSTEMACCTPUBNKEY} 

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
fi

echo -e "\nWriting server configuration:\n"
tee ./conf/server.conf <<EOF
server_name: ${SERVERNAME}
client_advertise: "${NATSHOST}:${NATSPORT}"
port: ${NATSPORT}
monitor_port: ${NATSMONITORPORT} 

jetstream {
  store_dir: "${DIRPREFIX}/state"
}
EOF

if [ "$PKI" = "true" ]; then
tee --append ./conf/server.conf <<EOF
operator: "${DIRPREFIX}/vault/nats/${OPERATORNAME}/${OPERATORNAME}.jwt"
system_account: "${SYSTEMACCTPUBNKEY}"

resolver: {
  type: full
  dir: "${DIRPREFIX}/state/.jwt"
  allow_delete: true
  interval: "2m"
  limit: 1000
}
EOF
else
tee --append ./conf/server.conf <<EOF
accounts: {
    AcctA: {
	  jetstream: enabled 
	  users: [ {user: UserA1, password: s3cr3t}, {user: UserA2, password: s3cr3t} ]
	},
    AcctB: {
	  jetstream: enabled
	  users: [ {user: UserB1, password: s3cr3t}, {user: UserB2, password: s3cr3t} ]
	},
    AcctC: {
	  jetstream: enabled
	  users: [ {user: UserC1, password: s3cr3t}, {user: UserC2, password: s3cr3t} ]
	},
	${SYSTEMACCTNAME}: {
	    users: [ {user: ${SYSTEMUSERNAME}, password: s3cr3t} ]
    }
}
system_account: "${SYSTEMACCTNAME}" 
EOF
fi

if [ "$DOCKER" = "true" ]; then
echo -e "\nWriting server start script (docker):\n"
tee ./run-server.sh <<EOF
#!/bin/bash

docker run -d \\
  --mount type=bind,source="$(pwd)/conf",target=/conf \\
  --mount type=bind,source="$(pwd)/vault",target=/vault \\
  --mount type=bind,source="$(pwd)/state",target=/state \\
  -p ${NATSPORT}:${NATSPORT} \\
  -p ${NATSMONITORPORT}:${NATSMONITORPORT} \\
  nats:latest --config /conf/server.conf
EOF
else
echo -e "\nWriting server start script:\n"
tee ./run-server.sh <<EOF
#!/bin/bash

nats-server --config "$(pwd)/conf/server.conf"
EOF
fi
chmod u+x ./run-server.sh

echo -e "\nWriting env.json file:\n"
tee ./conf/env.json <<EOF
{
 "PKI": "${PKI}",
 "DOCKER": "${DOCKER}",
 "SERVERNAME": "${SERVERNAME}",
 "NATSHOST": "${NATSHOST}",
 "NATSPORT": "${NATSPORT}",
 "NATSMONITORPORT": "${NATSMONITORPORT}",
 "OPERATORNAME": "${OPERATORNAME}",
 "SYSTEMACCTNAME": "${SYSTEMACCTNAME}",
 "SYSTEMUSERNAME": "${SYSTEMUSERNAME}",
 "NATSURL": "nats://${NATSHOST}:${NATSPORT}",
 "MONITORURL": "http://${NATSHOST}:${NATSMONITORPORT}"
}
EOF
