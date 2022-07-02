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
  default = "ami-0ccffa414772be4aa"
}
variable "ec2_instance_type" {
  description = "Instance type"
  default = "t2.micro"
}
variable "route53_zone_id" {
  description = "Route53 zone id"
  default = "Z036374065L40GHHCTH5"
}