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
          sudo apt-get update
          sudo apt-get install ca-certificates curl
          sudo install -m 0755 -d /etc/apt/keyrings
          sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
          sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the docker repository to Apt sources:
          echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          sudo apt-get update

        # Install docker 
          yes | sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Get monitoring stack repository

          git clone https://github.com/techbabette/MonitoringStack.git
          cd MonitoringStack

        # Run simple monitoring stack

          cd SimpleDeployment
          sudo docker compose up -d

          echo 'Script executed successfully!' >> /run/testing.txt      
      permissions: '0755'

  runcmd:
  - [ sh, "/run/scripts/initialize.sh" ]
  EOF
}