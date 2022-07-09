variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ssh_public_key_src_path" {
  type = string
  default = "/Users/hanchiang/.ssh/url_shortener_rsa.pub"
}

variable "ssh_public_key_dest_path" {
  type = string
  default = "/tmp/url_shortener_rsa.pub"
}

variable "postgres_schema_src_path" {
  type = string
  default = "/Users/hanchiang/Documents/CODING-PROJECTS/NODE/url-shortener/url-shortener-infra/images/scripts/db/postgres-schema.sql"
}

variable "postgres_schema_dest_path" {
  type = string
  default = "/tmp/postgres-schema.sql"
}

variable "postgres_password_src_path" {
  type = string
  default = "/Users/hanchiang/Documents/CODING-PROJECTS/NODE/url-shortener/url-shortener-infra/secrets/postgres/user_password.txt"
}

variable "postgres_password_dest_path" {
  type = string
  default = "/tmp/postgres-user-password.txt"
}


# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioners and post-processors on a
# source.
source "amazon-ebs" "url_shortener" {
  ami_name      = "url_shortener"
  instance_type = "t2.micro"
  region        = var.region
  force_deregister   = true
  force_delete_snapshot = true
  ssh_username = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 8
  }
  
}

build {
    sources = ["source.amazon-ebs.url_shortener"]

    provisioner "file" {
      source = var.ssh_public_key_src_path
      destination = var.ssh_public_key_dest_path
    }

    provisioner "file" {
      source = var.postgres_schema_src_path
      destination = var.postgres_schema_dest_path
    }

    provisioner "file" {
      source = var.postgres_password_src_path
      destination = var.postgres_password_dest_path
    }

    provisioner "shell" {
      scripts = ["./scripts/setup-user.sh", "./scripts/install-software.sh"]
      env = {
        SSH_PUBLIC_KEY_PATH: var.ssh_public_key_dest_path
        POSTGRES_SCHEMA_PATH: var.postgres_schema_dest_path
        POSTGRES_PASSWORD_PATH: var.postgres_password_dest_path
      }
    }
}