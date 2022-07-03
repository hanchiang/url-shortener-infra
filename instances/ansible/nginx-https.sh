#! /bin/bash

SSH_USER=$1
SSH_PRIVATE_KEY_PATH=$2

dir=$(dirname $0)
cd $dir

DOMAIN="api.urlshortener.yaphc.com"
nslookup $DOMAIN
while [ $? -ne 0 ];
do
    echo "Waiting for DNS for $DOMAIN to be propagated..."
    sleep 5
    nslookup $DOMAIN
done

echo "DNS for $DOMAIN is propagated!"

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u $SSH_USER -i aws_ec2.yml --private-key $SSH_PRIVATE_KEY_PATH nginx-https.yml