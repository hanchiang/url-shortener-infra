# Introduction
The scripts folder contains scripts to automate starting and stopping of AWS EC2, DNS, and deployment of [URL shortener backend](https://github.com/hanchiang/url-shortener-backend)
Scripts should be run at this directory.

`start.sh`
* Start EC2
* Update route53 record, wait for DNS record to be updated
* Mount EBS volume
* Copy postgres data to volume
* Configure SSL for nginx
* Re-run github action deployment job for URL shortener

`stop.sh`
* Remove route53 record
* Stop EC2