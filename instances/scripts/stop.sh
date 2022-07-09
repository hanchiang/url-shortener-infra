#! /bin/bash

set -e

dir=$(dirname $0)
cd $dir

source ./helper/ec2-helper.sh

instance_info=$(get_instance_info)
echo $instance_info
instance_state=$(echo $instance_info | jq -r '.state')
instance_id=$(echo $instance_info | jq -r .'id')

if [ "$instance_state" = "running" ]
then
    echo "Stopping ec2 $instance_id"
    aws ec2 stop-instances --instance-ids $instance_id > /dev/null 2>&1
else
    echo "ec2 $instance_id is not running"
    exit 0
fi
