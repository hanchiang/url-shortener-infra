variable "cidr_vpc" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}
variable "cidr_subnet" {
  description = "CIDR block for the subnet"
  default     = "10.1.0.0/24"
}
variable "region"{
  description = "The region Terraform deploys your instance"
  default = "us-east-1"
}
variable "ec2_ami" {
  description = "AMI of the EC2 to be provisioned"
  default = "ami-0c6f0bbec36bbb9c8"
}
variable "ec2_instance_type" {
  description = "Instance type"
  default = "t2.micro"
}
variable "route53_zone_id" {
  description = "Route53 zone id"
  default = "Z036374065L40GHHCTH5"
}
variable "ssh_private_key_path" {
  description = "Private SSH key for EC2"
  default = "/Users/hanchiang/.ssh/url_shortener_rsa"
  sensitive = true
}

variable "ssh_public_key_path" {
  description = "Public SSH key for EC2"
  default = "/Users/hanchiang/.ssh/url_shortener_rsa.pub"
}

variable "ssh_user" {
  default = "han"
  sensitive = true
}