#! /bin/bash

set -u

dir=$(dirname $0)
cd $dir

SSH_USER=$1
SSH_PRIVATE_KEY_PATH=$2

usage () {
    echo "start usage: <path/to/script> domain> <ssh user> <ssh private key path>"
    exit 1
}

if [ -z "$SSH_USER"  ];
then
    usage
fi

if [ -z "$SSH_PRIVATE_KEY_PATH"  ];
then
    usage
fi

ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u $SSH_USER -i aws_ec2.yml --private-key $SSH_PRIVATE_KEY_PATH setup-file-system.yml