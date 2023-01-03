#!/bin/bash

source ./setnscenv.sh

# EDIT THESE
## PKI can be "false" (user passwords), "true" (user JWT/nkey), or "mtls" (user client TLS/x509 map)
PKI="mtls"
DOCKER="false"
SERVERNAME="nats-cafe"
NATSHOST="localhost"
NATSPORT="4322"
NATSMONITORPORT="8322"
OPERATORNAME="NatsOp"
SYSTEMACCTNAME="SYS"
SYSTEMUSERNAME="System"
############

OPERATORSERVICEURL="nats://${NATSHOST}:${NATSPORT}"
OPERATORJWTSERVERURL="nats://${NATSHOST}:${NATSPORT}"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

if [ "$DOCKER" = "true" ]; then
  DIRPREFIX=""
else
  DIRPREFIX="$(pwd)"
fi

if [ "$PKI" = "true" ]; then
# Instantiate Decentralized NATS Auth
  nsc env --store $SCRIPT_DIR/vault/nats
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
elif [ "$PKI" = "mtls" ]; then
# Instantiate CA and TLS certificates
  # server-side
  mkcert -install
  # so that we are self-contained and can optionally run as container...
  cp `mkcert -CAROOT`/rootCA.pem ./vault/rootCA.pem
  mkcert -cert-file ./vault/server-cert.pem -key-file ./vault/server-key.pem ${NATSHOST} ::1
  # client-side
  mkcert -client -cert-file ./vault/System-cert.pem -key-file ./vault/System-key.pem System@user.net
  mkcert -client -cert-file ./vault/UserA1-cert.pem -key-file ./vault/UserA1-key.pem UserA1@user.net
  mkcert -client -cert-file ./vault/UserA2-cert.pem -key-file ./vault/UserA2-key.pem UserA2@user.net
  mkcert -client -cert-file ./vault/UserB1-cert.pem -key-file ./vault/UserB1-key.pem UserB1@user.net
  mkcert -client -cert-file ./vault/UserB2-cert.pem -key-file ./vault/UserB2-key.pem UserB2@user.net
  mkcert -client -cert-file ./vault/UserC1-cert.pem -key-file ./vault/UserC1-key.pem UserC1@user.net
  mkcert -client -cert-file ./vault/UserC2-cert.pem -key-file ./vault/UserC2-key.pem UserC2@user.net
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
# Decentralized NATS Auth server conf
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
elif [ "$PKI" = "mtls" ]; then
# mTLS NATS Auth server conf
tee --append ./conf/server.conf <<EOF

tls: {
  cert_file: "./vault/server-cert.pem"
  key_file: "./vault/server-key.pem"
  ca_file: "./vault/rootCA.pem"
  timeout: 1

  # require client cert validation and match cert SAN to a user below
  verify_and_map: true
}

accounts: {
    AcctA: {
	  jetstream: enabled
	  users: [ {user: UserA1@user.net}, {user: UserA2@user.net} ]
	},
    AcctB: {
	  jetstream: enabled
	  users: [ {user: UserB1@user.net}, {user: UserB2@user.net} ]
	},
    AcctC: {
	  jetstream: enabled
	  users: [ {user: UserC1@user.net}, {user: UserC2@user.net} ]
	},
	${SYSTEMACCTNAME}: {
	    users: [ {user: ${SYSTEMUSERNAME}@user.net} ]
    }
}
system_account: "${SYSTEMACCTNAME}"
EOF
else
# Password NATS Auth server conf
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
