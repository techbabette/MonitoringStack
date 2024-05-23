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

# Add prometheus machine address to config and run grafana

    cd AWSDeployment
    cd grafana

    echo -e "  url: http://${prometheus_address}:9090" >> grafana/grafana.yml

    sudo docker compose up -d

    echo "Script executed successfully, prometheus ip is ${prometheus_address}" >> /run/testing.txt      