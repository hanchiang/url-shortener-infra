variable "region" {
  type    = string
  default = "us-east-1"
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

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ssh_username = "ubuntu"
}

build {
    sources = ["source.amazon-ebs.url_shortener"]

    provisioner "file" {
      source = "/Users/hanchiang/.ssh/url_shortener_rsa.pub"
      destination = "/tmp/url_shortener_rsa.pub"
    }

    provisioner "file" {
      source = "/Users/hanchiang/Documents/CODING-PROJECTS/NODE/url-shortener/url-shortener-infra/scripts/db/postgres-schema.sql"
      destination = "/tmp/postgres-schema.sql"
    }

    provisioner "file" {
      source = "/Users/hanchiang/Documents/CODING-PROJECTS/NODE/url-shortener/url-shortener-infra/secrets/postgres/user_password.txt"
      destination = "/tmp/postgres-user-password.txt"
    }

    provisioner "shell" {
      scripts = ["../scripts/setup-user.sh", "../scripts/install-software.sh"]
    }
}