#EC2 INSTANCES
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