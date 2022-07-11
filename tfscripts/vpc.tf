# resource "aws_vpc" "adserverx_vpc" {
#  cidr_block = "${var.vpc_cidr}"
#  enable_dns_hostnames = true
#  tags = {
#      Name = "adserverx_vpc1"
#      Role = "adserverx vpc1"
#  }
# }

# resource "aws_security_group" "adserverx_aws_nat_sg" {
#  name = "adserverx_nat_sg"
#  description = "Allow traffic to pass from the private subnet to the internet"
#  ingress {
#    from_port = 80
#    to_port = 80
#    protocol = "tcp"
#    cidr_blocks = ["${var.subnet_cidrs_private[0]}"]
#  }
#  ingress {
#    from_port = 443
#    to_port = 443
#    protocol = "tcp"
#    cidr_blocks = ["${var.subnet_cidrs_private[0]}"]
#  }
#  ingress {
#    from_port = -1
#    to_port = -1
#    protocol = "icmp"
#    cidr_blocks = ["${var.subnet_cidrs_private[0]}"]
#  }
#  egress {
#    from_port = 0
#    to_port = 0
#    protocol = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#  vpc_id = "${aws_vpc.adserverx_vpc.id}"
#  tags = {
#      Name = "adserverx_aws_nat_sg1"
#      Role = "ADserverx NAT Security Group1"
#  }
# }
# output "nat_sg_id" {
#  value = "${aws_security_group.adserverx_aws_nat_sg.id}"
# }

# resource "aws_internet_gateway" "adserverx_igw" {
#  vpc_id = "${aws_vpc.adserverx_vpc.id}"
#  tags = {
#      Name = "adserverx_igw1"
#      Role = "adserverx igw1"
#  }
# }
# output "vpc_id" {
#  value = "${aws_vpc.adserverx_vpc.id}"
# }

# #
# # NAT Instance
# #
# resource "aws_instance" "adserverx_nat" {
#  ami = "${var.ami_nat_instance}" # this is a special ami preconfigured to do NAT
#  availability_zone = "us-east-1a"
#  instance_type = "t2.micro"
#  key_name = "${var.ec2_keypair_name}"
#  security_groups = ["${aws_security_group.adserverx_aws_nat_sg.id}"]
#  subnet_id = "${aws_subnet.adserverx_public_subnet.id}"
#  associate_public_ip_address = true
#  source_dest_check = false
#  tags = {
#      Name = "adserverx_nat_instance1"
#      Role = "adserverx nat instance1"
#  }
# }

# resource "aws_eip" "adserverx_nat_eip" {
#  instance = "${aws_instance.adserverx_nat.id}"
#  vpc = true
#  tags = {
#      Name = "adserverx_nat_eip1"
#      Role = "adserverx nat eip1"
#  }
# }

# #
# # Public Subnets
# #
# resource "aws_subnet" "adserverx_public_subnet" {
#  vpc_id = "${aws_vpc.adserverx_vpc.id}"
#  cidr_block = "${var.public_subnet_cidr}"
#  availability_zone = "us-east-1a"
#  tags = {
#      Name = "adserverx_public_subnet1"
#      Role = "adserverx public subnet1"
#  }
# }
# output "public_subnet_id" {
#  value = "${aws_subnet.adserverx_public_subnet.id}"
# }

# resource "aws_route_table" "adserverx_public_route" {
#  vpc_id = "${aws_vpc.adserverx_vpc.id}"
#  route {
#      cidr_block = "0.0.0.0/0"
#      gateway_id = "${aws_internet_gateway.adserverx_igw.id}"
#  }
#  tags = {
#      Name = "adserverx_public_subnet_route_table1"
#      Role = "adserverx public subnet route table1"
#  }
# }

# resource "aws_route_table_association" "adserverx_public_subnet_rtable_assoc" {
#  subnet_id = "${aws_subnet.adserverx_public_subnet.id}"
#  route_table_id = "${aws_route_table.adserverx_public_route.id}"
# }

# #
# # Private Subnet
# #
# resource "aws_subnet" "adserverx_private_subnet" {
#  count = "${length(var.subnet_cidrs_private)}"
#  vpc_id = "${aws_vpc.adserverx_vpc.id}"
#  cidr_block = "${var.subnet_cidrs_private[count.index]}"
#  availability_zone = "${var.availability_zones[count.index]}"
#  tags = {
#      Name = "adserverx_private_subnet1"
#      Role = "adserverx private subnet1"
#  }
# }

# output "adserverx_private_first_subnet_output" {
#   value       = aws_subnet.adserverx_private_subnet[0].id
#   description = "private first subnet output"
# }
# output "adserverx_private_second_subnet_output" {
#   value       = aws_subnet.adserverx_private_subnet[1].id
#   description = "private second subnet output"
# }

# resource "aws_route_table" "adserverx_private_route_table" {
#  vpc_id = "${aws_vpc.adserverx_vpc.id}"
#  route {
#      cidr_block = "0.0.0.0/0"
#      instance_id = "${aws_instance.adserverx_nat.id}"
#  }
#  tags = {
#      Name = "adserverx_private_subnet_route_table1"
#      Role = "adserverx private subnet route table1"
#  }
# }

# resource "aws_route_table_association" "adserverx_private_route_table_assoc_1" {
#  subnet_id = "${aws_subnet.adserverx_private_subnet[0].id}"
#  route_table_id = "${aws_route_table.adserverx_private_route_table.id}"
#  depends_on = [aws_route_table.adserverx_private_route_table]
# }

# resource "aws_route_table_association" "adserverx_private_route_table_assoc_2" {
#  subnet_id = "${aws_subnet.adserverx_private_subnet[1].id}"
#  route_table_id = "${aws_route_table.adserverx_private_route_table.id}"
#  depends_on = [aws_route_table.adserverx_private_route_table]
# }
