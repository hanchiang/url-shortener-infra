# Introduction
![example workflow](https://github.com/hanchiang/url-shortener-infra/actions/workflows/health_check.yml/badge.svg)
![example workflow](https://github.com/hanchiang/url-shortener-infra/actions/workflows/start_url_shortener.yml/badge.svg)
![example workflow](https://github.com/hanchiang/url-shortener-infra/actions/workflows/stop_url_shortener.yml/badge.svg)

This project is the infrastructure as code management for [URL shortener backend](https://github.com/hanchiang/url-shortener-backend) using AWS.

# Structure
* `images/`: Packer files for building AMI
    * `image.pkr.hcl`: Main packer script
    * `scripts/`: Scripts to be run when provisioning AMI
* `instances/`: Terraform files to provision EC2 in VPC
    * `main.tf`: Main terraform script
    * `ansible/`: Ansible scripts to run post-provisioning tasks such as mounting EBS volume, set up file system, copy postgres data, setup SSL for nginx 
    * `scripts/`: Scripts to automate(everything after step 2 of the workflow) start and stop of EC2, DNS, and deployment of [URL shortener backend](https://github.com/hanchiang/url-shortener-backend). Calls ansible scripts


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


Everything from here onwards is handled in `instances/scripts/start.sh`

## 3. Run ansible script
Run post-provisioning configurations such as mounting EBS volume, setting PostGreSQL data directory, nginx SSL, grafana

## 4. Deploy application
Rerun the latest deploy job in github action

## Diagram
**Traffic flow**
![](diagrams/traffic-flow.drawio.png)

**Deployment pipeline**
![](diagrams/deployment-pipeline.drawio.png)


# Operational hours
EC2 and URL shortener will run from:
* 5am UTC - 3pm UTC on weekdays
* 2am UTC - 3pm UTC on weekends

## TODO:
* Use ansible roles to define reusable configurations
* Use terraform modules to define reusable configurations
* IAM user and policies for system admin
* container image scan
* Use terraform vault to store secrets
* Nginx: GeoIP2 https://github.com/leev/ngx_http_geoip2_module
* Create postgres roles and user: app, grafana
* Grafana: Traces, alerts on infra & app, monitor grafana itself

# Learnings:
* Messed up PostGreSQL WAL by `rsync`ing `/var/lib/postgresql/13/main/` to its new data directory. Don't do it.