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

files=($(ls playbooks/*.yml))

# Configure and mount EBS volume
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u $SSH_USER -i aws_ec2.yml --private-key $SSH_PRIVATE_KEY_PATH playbooks/setup-file-system.yml

# Copy postgres data to volume
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u $SSH_USER -i aws_ec2.yml --private-key $SSH_PRIVATE_KEY_PATH playbooks/copy-postgres-data.yml

# Configure ssl for nginx
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u $SSH_USER -i aws_ec2.yml --private-key $SSH_PRIVATE_KEY_PATH playbooks/nginx-https.yml

# Configure grafana
ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u $SSH_USER -i aws_ec2.yml --private-key $SSH_PRIVATE_KEY_PATH playbooks/grafana.yml




