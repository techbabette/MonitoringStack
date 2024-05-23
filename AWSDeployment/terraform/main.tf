terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "access_key" {
  sensitive = true
}

variable "secret_key" {
  sensitive = true
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-north-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# SUBNETS
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private"
  }
}

# GATEWAYS
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tigw"
  }
}

resource "aws_eip" "ngw_eip" {
  domain           = "vpc"

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw_eip.id
  subnet_id     = aws_subnet.public.id

  connectivity_type = "public"
  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.igw]
}

# ROUTE TABLES
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "publicrt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "privatert"
  }
}

#ROUTE TABLE ASSOCIATIONS
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

#SECURITY GROUPS
resource "aws_security_group" "public_grafana" {
  name        = "public_grafana"
  description = "Allow inbound traffic to port 3000 and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "public_grafana"
  }
}

resource "aws_security_group" "private_prometheus" {
  name        = "private_prometheus"
  description = "Allow inbound traffic to port 9090 and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "private_prometheus"
  }
}

#SECURITY GROUP INGRESS RULES
resource "aws_vpc_security_group_ingress_rule" "allow_public_grafana" {
  security_group_id = aws_security_group.public_grafana.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

resource "aws_vpc_security_group_ingress_rule" "allow_private_prometheus" {
  security_group_id = aws_security_group.private_prometheus.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 9090
  ip_protocol       = "tcp"
  to_port           = 9090
}

#SECURITY GROUP EGRESS RULES
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_grafana" {
  security_group_id = aws_security_group.public_grafana.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_prometheus" {
  security_group_id = aws_security_group.private_prometheus.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6_grafana" {
  security_group_id = aws_security_group.public_grafana.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6_prometheus" {
  security_group_id = aws_security_group.private_prometheus.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#EC2 INSTANCES
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "private_prometheus" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_prometheus.id]

  user_data = "${file("prometheus_init.sh")}"

  tags = {
    Name = "private_prometheus"
  }

  depends_on = [ aws_route_table_association.private, aws_route_table_association.public ]
}

data "template_file" "init" {
  template = "${file("grafana_init.sh")}"

  vars = {
    prometheus_address = "${aws_instance.private_prometheus.private_ip}"
  }
}

resource "aws_instance" "public_grafana" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.public_grafana.id]

  tags = {
    Name = "public_grafana"
  }

  user_data = "${data.template_file.init.rendered}"

  depends_on = [ aws_instance.private_prometheus ]
}