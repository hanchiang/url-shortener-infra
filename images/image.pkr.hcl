variable "region" {
  type    = string
  default = "us-east-1"
}

variable "ssh_public_key_src_path" {
  type = string
  default = ""
}

variable "ssh_public_key_dest_path" {
  type = string
  default = "/tmp/url_shortener_rsa.pub"
}

variable "postgres_password_src_path" {
  type = string
  default = ""
}

variable "postgres_password_dest_path" {
  type = string
  default = "/tmp/postgres-user-password.txt"
}

variable "fs_mount_path" {
  type = string
  default = "/mnt/data"
}

variable "maxmind_account_id" {
  type = string
  default = ""
}

variable "maxmind_license_key" {
  type = string
  default = ""
}

variable "admin_email" {
  type = string
  default = ""
}

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioners and post-processors on a
# source.
source "amazon-ebs" "url_shortener" {
  ami_name      = "url_shortener"
  instance_type = "t4g.micro"
  region        = var.region
  force_deregister   = true
  force_delete_snapshot = true
  ssh_username = "ubuntu"

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd/*ubuntu-jammy-22.04-arm64-server*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }

  tags = {
    Name = "URL_shortener"
  }
}

build {
    sources = ["source.amazon-ebs.url_shortener"]

    provisioner "file" {
      source = var.ssh_public_key_src_path
      destination = var.ssh_public_key_dest_path
    }

    provisioner "file" {
      source = var.postgres_password_src_path
      destination = var.postgres_password_dest_path
    }

    provisioner "shell" {
      scripts = ["./scripts/setup-user.sh"]
      env = {
        SSH_PUBLIC_KEY_PATH: var.ssh_public_key_dest_path
        USER: "han"
      }
    }

    provisioner "shell" {
      scripts = ["./scripts/install-postgres.sh"]
      env = {
        POSTGRES_PASSWORD_PATH: var.postgres_password_dest_path
        FS_MOUNT_PATH: var.fs_mount_path
        USER: "han"
      }
    }

    provisioner "shell" {
      scripts = ["./scripts/install-redis.sh"]
    }

    provisioner "shell" {
      scripts = ["./scripts/install-nginx.sh"]
      env = {
        FS_MOUNT_PATH: var.fs_mount_path
        USER: "han",
        DOMAIN: "api.urlshortener.yaphc.com"
        URL_REDIRECT_DOMAIN: "go.yaphc.com",
        ADMIN_EMAIL: var.admin_email
        MAXMIND_ACCOUNT_ID: var.maxmind_account_id,
        MAXMIND_LICENSE_KEY: var.maxmind_license_key,
        ADMIN_EMAIL: var.admin_email
      }
    }

    provisioner "shell" {
      scripts = ["./scripts/install-docker.sh"]
      env = {
        USER: "han"
      }
    }

    provisioner "shell" {
      inline = [
        "sudo lsblk -f",
        "df -h"
      ]
    }
}
