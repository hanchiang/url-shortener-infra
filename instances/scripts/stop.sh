#! /bin/bash

set -eu

dir=$(dirname $0)
cd $dir

DOMAIN=$1

if [ -z "$DOMAIN" ]
then
    echo "domain is required. usage: <path/to/script> <domain>"
    exit 1
fi

source ./helper/ec2-helper.sh

instance_info=$(get_instance_info)
echo $instance_info
instance_state=$(echo $instance_info | jq -r '.state')
instance_ip_address=$(echo $instance_info | jq -r '.ip_address')
instance_id=$(echo $instance_info | jq -r .'id')

if [ "$instance_state" = "running" ]
then
    echo "Removing route53 record for instance $instance_id, ip $instance_ip_address"
    ./route53/update-ec2-route53.sh $DOMAIN "DELETE"
    
    echo "Stopping ec2 $instance_id"
    aws ec2 stop-instances --instance-ids $instance_id > /dev/null
else
    echo "ec2 $instance_id is not running"
    exit 0
fi
