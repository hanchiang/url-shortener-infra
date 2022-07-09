#! /bin/bash

set -e

DOMAIN=$1

if [ -z "$DOMAIN" ]
then
    echo "update route53 usage: <path/to/script> <domain>"
    exit 1
fi

source ./helper/ec2-helper.sh

instance_info=$(get_instance_info)
instance_ip_address=$(echo $instance_info | jq -r '.ip_address')
instance_state=$(echo $instance_info | jq -r '.state')
instance_id=$(echo $instance_info | jq -r .'id')

echo "Updating route53 record for instance $instance_id"

while [ "$instance_state" != "running" ];
do
    echo "Waiting for instance to be running"
    sleep 5

    instance_info=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=URL_shortener" --query 'Reservations[0].Instances[0].{ip_address:PublicIpAddress,state:State.Name,id:InstanceId}' --output json)
    instance_ip_address=$(echo $instance_ip_address | jq -r '.ip_address')
    instance_state=$(echo $instance_ip_address | jq -r '.state')
    instance_id=$(echo $instance_ip_address | jq -r .'id')
done
echo "Instance is running"

#### Update route53 record set
echo "Updating route53 record with ip address $instance_ip_address"
record_set_file="route53/change-record-set.json"
record_set_template_file="route53/change-record-set.json.tpl"

cat $record_set_template_file | sed "s~INSTANCE_IP_ADDRESS~$instance_ip_address~g" \
| sed "s~DOMAIN~$DOMAIN~g" > $record_set_file
aws route53 change-resource-record-sets --hosted-zone-id Z036374065L40GHHCTH5 --change-batch file://$record_set_file > /dev/null 2>&1

rm $record_set_file
echo "Updated route53 record with ip address $instance_ip_address"
