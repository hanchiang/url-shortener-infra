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
  default = "ami-0a2b83b3d21c32bd2"
}
variable "ec2_instance_type" {
  description = "Instance type"
  default = "t2.micro"
}