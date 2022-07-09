{
    "Comment": "Upsert route53 record for url_shortener",
    "Changes": [
        {
            "Action": "UPSERT",
            "ResourceRecordSet": {
                "Name": "DOMAIN",
                "Type": "A",
                "TTL": 300,
                "ResourceRecords": [
                    {
                        "Value": "INSTANCE_IP_ADDRESS"
                    }
                ]
            }
        }
    ]
}