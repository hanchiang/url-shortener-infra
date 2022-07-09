# Introduction
The scripts folder contains scripts to automate starting and stopping of AWS EC2, DNS, and deployment of [URL shortener backend](https://github.com/hanchiang/url-shortener-backend)
Scripts should be run at this directory.

`start.sh`
* Starts EC2
* Update route53 record, wait for DNS record to be updated
* Re-run github action deployment job
* Configure let's encrypt for nginx