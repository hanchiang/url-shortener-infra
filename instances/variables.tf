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

variable "ec2_instance_type" {
  description = "Instance type"
  default = "t2.micro"
}

variable "ec2_az" {
  description = "Availability zone"
  default = "us-east-1a"
}

variable "ssh_private_key_path" {
  description = "Private SSH key for EC2"
  default = "/Users/hanchiang/.ssh/url_shortener_rsa"
}

variable "ssh_public_key_path" {
  description = "Public SSH key for EC2"
  default = "/Users/hanchiang/.ssh/url_shortener_rsa.pub"
}

variable "ssh_user" {
  default = "han"
}

variable "url_shortener_ebs" {
  default = "vol-032cdd105723e4765"
}

data "aws_ami" "ec2_ami" {
  name_regex  = "^url_shortener$"
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


