# Prometheus Monitoring Stack

This repo contains two different deployment options for my monitoring stack, both work out of the box with terraform apply.

## [Simple deployment](https://github.com/techbabette/MonitoringStack/tree/main/SimpleDeployment)

Simple, single machine deployment of the stack.

All necessary services are defined in the [docker compose](https://github.com/techbabette/MonitoringStack/blob/main/SimpleDeployment/docker-compose.yml) file.

The [terraform file](https://github.com/techbabette/MonitoringStack/blob/main/SimpleDeployment/main.tf) starts the machine, installs docker, pulls this repo and starts the services.

Two ansible playbooks are available for [updating](https://github.com/techbabette/MonitoringStack/blob/main/SimpleDeployment/playbooks/pullandrebuild.yml) & [resetting](https://github.com/techbabette/MonitoringStack/blob/main/SimpleDeployment/playbooks/resetandrebuild.yml) the remote machine state.

The resulting graph can be viewed [here](http://91.107.230.206:3000/d/rYdddlPWk/node-exporter-full?orgId=1&refresh=1m&from=now-5m&to=now).

## [AWS Deployment](https://github.com/techbabette/MonitoringStack/tree/main/AWSDeployment)

### Architecture

The architecture shown below is created with a single terraform apply.

![Architecture](https://i.imgur.com/OBr1bfr.png "Architecture")

The Prometheus and Grafana EC2 instances can communicate as they are in the same VPC.

The Grafana instance is connected directly to the internet through an internet gateway.

The Prometheus instance is connected to the internet through a NAT gateway that relies on the previously mentioned internet gateway.

The NAT gateway allows the prometheus instance to send requests and receive responses but prevents any incoming requests from outside of the VPC, this allows it to poll monitored machines without allowing remote requests.