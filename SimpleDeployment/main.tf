terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
  }
}

variable "hcloud_token" {
  sensitive = true
}

provider "hcloud" {
  token = var.hcloud_token
}

variable "ntfy_user" {
  default = "admin"
}

variable "ntfy_password" {
  sensitive = true
}

resource "hcloud_server" "monitor1" {
  name        = "monitor1"
  server_type = "cax11"
  image       = "ubuntu-22.04"
  location    = "nbg1"

  user_data = <<EOF
  #cloud-config
  write_files:
    - path: /run/scripts/initialize.sh
      content: |
        #!/bin/bash

        # Add Docker's official GPG key:
          apt-get update
          apt-get install ca-certificates curl
          install -m 0755 -d /etc/apt/keyrings
          curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
          chmod a+r /etc/apt/keyrings/docker.asc

        # Add the docker repository to Apt sources:
          echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
          apt-get update

        # Install docker 
          yes | apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Get monitoring stack repository

          git clone https://github.com/techbabette/MonitoringStack.git
          cd MonitoringStack

        # Run simple monitoring stack

          cd SimpleDeployment
          docker compose up -d

          docker exec -i ntfy sh -c "
          while [ ! -f /var/lib/ntfy/auth.db ]; do
              echo 'Waiting for auth-file to be created...'
              sleep 1
          done
          yes ${var.ntfy_password} | ntfy user add --role=admin ${var.ntfy_user}"

          echo 'Script executed successfully!' >> /run/testing.txt      
      permissions: '0700'

  runcmd:
  - [ sh, "/run/scripts/initialize.sh" ]
  EOF
}

output "instance_ip_address" {
  value = hcloud_server.monitor1.ipv4_address
}