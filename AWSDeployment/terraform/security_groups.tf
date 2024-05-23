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