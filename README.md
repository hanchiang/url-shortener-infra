# Introduction
This project is the infrastructure as code management for [URL shortener backend](https://github.com/hanchiang/url-shortener-backend) using AWS.

# Structure
* `images/`: Packer files for building AMI
    * `scripts/`: Scripts to be run when provisioning AMI
* `instances/`: Terraform files to provision EC2 in VPC
    * `scripts/`: Scripts to automate start and stop of EC2, DNS, and deployment of [URL shortener backend](https://github.com/hanchiang/url-shortener-backend)


# Workflow
## 1. Provision EC2 AMI using packer
Provisions a EBS-backed EC2 AMI, and install the necessary softwares for [URL shortener backend](https://github.com/hanchiang/url-shortener-backend), i.e. postgres, redis, as well as nginx

cd into `images/`
Define variables that are declared in `image.pkr.hcl` in a new file `variables.auto.pkrvars.hcl`
Build image: `packer build -machine-readable -var-file variables.auto.pkrvars.hcl image.pkr.hcl | tee build.log`

## 2. Provision EC2 in a VPC using terraform
cd into `instances/`
Copy the AMI ID from packer build, update it in `variables.tf`
Provision infra: `terraform apply`

## 3. Set up let's encrypt with nginx**
Make sure DNS is mapped for EC2 before proceeding.

This needs to be done after EC2 is provisioned and its IP addresss is set in route 53
`ansible/nginx-https.sh <ssh user> <ssh private key path>`