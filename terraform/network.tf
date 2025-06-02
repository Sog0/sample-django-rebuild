#############
# VPC BLOCK #
#############

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.main_vpc.id
  count = 2
  cidr_block = var.public_subnets_cidrs[count.index]
  availability_zone = var.azs[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.main_vpc.id
  count = 2
  cidr_block = var.private_subnets_cidrs[count.index]
  availability_zone = var.azs[count.index]
}

##########################
# INTERNET GATEWAY BLOCK #
##########################

resource "aws_internet_gateway" "vpc_main_igw" {
  vpc_id = aws_vpc.main_vpc.id
}

###############
# ROUTE BLOCK #
###############

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    name = "private"
  }
}

resource "aws_route" "external_route_public" {
  route_table_id = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.vpc_main_igw.id
}

resource "aws_route" "external_route_private" {
  route_table_id = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "public_rt_assoc" {
  count = length(var.public_subnets_cidrs)
  subnet_id = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_rt_assoc" {
  count = length(var.private_subnets_cidrs)
  subnet_id = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

###############
# NAT GATEWAY #
###############

resource "aws_eip" "nat_eip" {
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets[0].id
}

########################
# SECURITY GROUP BLOCK #
########################

resource "aws_security_group" "internal_sg" {
  vpc_id = aws_vpc.main_vpc.id
  name = "internal_sg"
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main_vpc.id
  name = "alb_sg"
}


resource "aws_vpc_security_group_ingress_rule" "alb_allow_http" { 
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "instance_allow_ssh" { 
  security_group_id = aws_security_group.internal_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "instance_allow_http" { 
  security_group_id = aws_security_group.internal_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "instance_allow" {
  security_group_id = aws_security_group.internal_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "alb_allow" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_security_group" "bastion_sg"{
  vpc_id = aws_vpc.main_vpc.id
  name = "bastion_sg"

}

resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.main_vpc.id
  name = "db_sg"
}

resource "aws_vpc_security_group_ingress_rule" "bastion_allow_ssh_in" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "bastion_allow_all_out" {
  security_group_id = aws_security_group.bastion_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "db_allow_all_in" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}

resource "aws_vpc_security_group_egress_rule" "db_allow_all_out" {
  security_group_id = aws_security_group.db_sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = "-1"
}




# ###########
# # TEST###
# ###########

# locals {
#   services = {
#     "ec2messages" : {
#       "name" : "com.amazonaws.${var.region}.ec2messages"
#     },
#     "ssm" : {
#       "name" : "com.amazonaws.${var.region}.ssm"
#     },
#     "ssmmessages" : {
#       "name" : "com.amazonaws.${var.region}.ssmmessages"
#     }
#   }
# }

# resource "aws_vpc_endpoint" "ssm_endpoint" {
#   for_each = local.services
#   vpc_id   = aws_vpc.main_vpc.id
#   service_name        = each.value.name
#   vpc_endpoint_type   = "Interface"
#   security_group_ids  = [aws_security_group.ssm_https.id]
#   private_dns_enabled = true
#   ip_address_type     = "ipv4"
#   subnet_ids          = [for subnet in aws_subnet.private_subnets : subnet.id]
# }

# resource "aws_security_group" "ssm_https" {
#   name        = "allow_ssm"
#   description = "Allow SSM traffic"
#   vpc_id      = aws_vpc.main_vpc.id

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = var.private_subnets_cidrs
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }