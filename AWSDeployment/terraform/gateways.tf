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