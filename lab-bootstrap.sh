#/bin/bash

source ./setnscenv.sh

# EDIT THESE
PKI="true"
TLS="true"
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

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"



if [ "$PKI" = "true" ]; then
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
fi

if [ "$TLS" = "true" ]; then
  mkcert -install
  mkcert -cert-file tls/server-cert.pem -key-file tls/server-key.pem localhost ::1
  mkcert -client -cert-file tls/client-cert.pem -key-file tls/client-key.pem localhost ::1 email@localhost
  cp "$(mkcert -CAROOT)/rootCA.pem" tls/rootCA.pem
  openssl x509 -noout -text -in tls/server-cert.pem
  sleep 2
  openssl x509 -noout -text -in tls/client-cert.pem
  sleep 2
  openssl pkcs12 -export -out tls/keystore.p12 -inkey tls/client-key.pem \
    -in tls/client-cert.pem -password pass:password
  keytool -importkeystore -srcstoretype PKCS12 -srckeystore tls/keystore.p12 \
    -srcstorepass password -destkeystore tls/keystore.jks -deststorepass password
  keytool -importcert -trustcacerts -file tls/rootCA.pem \
    -storepass password -noprompt -keystore tls/truststore.jks
fi

echo -e "\nWriting server configuration:\n"
tee ./conf/server.conf <<EOF
server_name: ${SERVERNAME}
client_advertise: "${NATSHOST}:${NATSPORT}"
port: ${NATSPORT}
monitor_port: ${NATSMONITORPORT}

jetstream {
  store_dir: "./state"
}
EOF

if [ "$TLS" = "true" ]; then
  tee -a ./conf/server.conf <<EOF
tls {
  cert_file: "tls/server-cert.pem"
  key_file:  "tls/server-key.pem"
  ca_file:   "tls/rootCA.pem"
  verify:    true
}

EOF
fi

if [ "$PKI" = "true" ]; then
tee -a ./conf/server.conf <<EOF
operator: "./vault/nats/${OPERATORNAME}/${OPERATORNAME}.jwt"
system_account: "${SYSTEMACCTPUBNKEY}"

resolver: {
  type: full
  dir: "./state/.jwt"
  allow_delete: true
  interval: "2m"
  limit: 1000
}
EOF
else
tee -a ./conf/server.conf <<EOF
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

nats-server --config "./conf/server.conf"
EOF
fi
chmod u+x ./run-server.sh

echo -e "\nWriting env.json file:\n"
tee ./conf/env.json <<EOF
{
 "PKI": "${PKI}",
 "TLS": "${TLS}",
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
