#!/bin/bash
export FQDN=app.demo
mkdir ${FQDN} && envsubst < cert-template.cnf > ${FQDN}/${FQDN}.cnf
openssl req -new -newkey rsa:4096 -nodes -keyout ${FQDN}/${FQDN}.key -out ${FQDN}/${FQDN}.csr -config ${FQDN}/${FQDN}.cnf
openssl x509 -req -in ${FQDN}/${FQDN}.csr -signkey ${FQDN}/${FQDN}.key -out ${FQDN}/${FQDN}.crt -days 365
openssl x509 -in ${FQDN}/${FQDN}.crt -text -noout
cat ${FQDN}/${FQDN}.crt ${FQDN}/${FQDN}.key > app-demo-combined.pem
