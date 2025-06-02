#################
# APP INSTANCES #
#################

resource "aws_instance" "django-app" {
  ami  = "ami-0953476d60561c955"
  vpc_security_group_ids = [aws_security_group.internal_sg.id]
  instance_type = "${var.instance_type}"
  count = 2
  subnet_id = aws_subnet.private_subnets[count.index].id
  key_name = aws_key_pair.test-key-pair.key_name
  tags = {
    Name = "app-instance-${count.index}"
  }
}

################
# DB INSTANCES #
################

resource "aws_instance" "db" {
  ami           = "ami-0953476d60561c955"
  instance_type = "t2.micro"
  key_name = aws_key_pair.test-key-pair.key_name
  count = 1
  subnet_id     = aws_subnet.private_subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  tags = {
    Name = "db-instance"
  }
}

#####################
# BASTION INSTANCES #
#####################

resource "aws_instance" "bastion" {
  ami           = "ami-0953476d60561c955"
  instance_type = "t2.micro"
  key_name = aws_key_pair.test-key-pair.key_name
  count = 1
  subnet_id = aws_subnet.public_subnets[count.index].id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  tags = {
    Name = "bastion-instance"
  }
}


################
# KEY PAIRS #
################

resource "aws_key_pair" "test-key-pair"{
  key_name = "key"
  public_key = file("id_rsa.pub")
}