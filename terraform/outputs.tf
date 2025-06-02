##########################
# App Instances Outputs  #
##########################

output "app_instance_ids" {
  description = "IDs of the Django application EC2 instances"
  value       = [for instance in aws_instance.django-app : instance.id]
}

output "app_private_ips" {
  description = "Private IPs of the Django application EC2 instances"
  value       = [for instance in aws_instance.django-app : instance.private_ip]
}

output "app_ssm_instance_names" {
  description = "SSM instance names for Django app instances"
  value       = [for instance in aws_instance.django-app : "i-${instance.id}"]
}

#########################
# DB Instance Outputs   #
#########################

output "db_instance_id" {
  description = "ID of the database EC2 instance"
  value       = aws_instance.db[0].id
}

output "db_private_ip" {
  description = "Private IP of the database EC2 instance"
  value       = aws_instance.db[0].private_ip
}

output "db_ssm_instance_name" {
  description = "SSM instance name for the DB instance"
  value       = "i-${aws_instance.db[0].id}"
}

##########################
# Load Balancer Outputs  #
##########################

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.demo_lb.dns_name
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.demo_lb.arn
}

######################
# Networking Outputs #
######################

output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [for subnet in aws_subnet.public_subnets : subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [for subnet in aws_subnet.private_subnets : subnet.id]
}


resource "local_file" "create-inventory" {
  content = templatefile("inventory-temp.tftpl", {
    django-app-ip1 = aws_instance.django-app[0].private_ip
    django-app-ip2 = aws_instance.django-app[1].private_ip,
    db_ip = aws_instance.db[0].private_ip,
    dns = aws_lb.demo_lb.dns_name,
    bastion_ip = aws_instance.bastion[0].public_ip
  })
  filename = "../ansible/inventory.ini"
}


resource "local_file" "change-config" {
  content = templatefile("config_ssh.tftpl", {
    bastion_ip = aws_instance.bastion[0].public_ip
  })
  filename = "~/.ssh/config"
}
