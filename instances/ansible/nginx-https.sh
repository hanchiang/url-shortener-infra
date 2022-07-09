#! /bin/bash

set -e

dir=$(dirname $0)
cd $dir

DOMAIN=$1
SSH_USER=$2
SSH_PRIVATE_KEY_PATH=$3

usage () {
    echo "start usage: <path/to/script> <domain> <ssh user> <ssh private key path>"
    exit 1
}

if [ -z "$DOMAIN"  ];
then
    usage
fi

if [ -z "$SSH_USER"  ];
then
    usage
fi

if [ -z "$SSH_PRIVATE_KEY_PATH"  ];
then
    usage
fi

echo "Setting up let's encrypt for nginx"

nslookup $DOMAIN
while [ $? -ne 0 ];
do
    echo "Waiting for DNS for $DOMAIN to be propagated..."
    sleep 5
    nslookup $DOMAIN
done

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u $SSH_USER -i aws_ec2.yml --private-key $SSH_PRIVATE_KEY_PATH nginx-https.yml
echo "HTTPS for nginx is set up successfully"