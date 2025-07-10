provider "aws" {
  region = var.region
}
 
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "hcl-custom-vpc" }
}
 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "hcl-igw" }
}
 
resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_a_cidr
  availability_zone       = var.az_a
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet-a" }
}
 
resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_b_cidr
  availability_zone       = var.az_b
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet-b" }
}
 
resource "aws_subnet" "subnet_c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_c_cidr
  availability_zone       = var.az_c
  map_public_ip_on_launch = true
  tags                    = { Name = "public-subnet-c" }
}
 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
 
  tags = { Name = "public-rt" }
}
 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}
 
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}
 
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.subnet_c.id
  route_table_id = aws_route_table.public_rt.id
}
 
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Allow HTTP access"
  vpc_id      = aws_vpc.main.id
 
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "alb-sg"
  }
}
 
resource "aws_lb" "app_alb" {
  name               = "hcl-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id,
    aws_subnet.subnet_c.id
  ]
 
  tags = {
    Name = "hcl-alb"
  }
}
 
resource "aws_lb_target_group" "tg_home" {
  name     = "tg-home"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}
 
resource "aws_lb_target_group" "tg_images" {
  name     = "tg-images"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}
 
resource "aws_lb_target_group" "tg_register" {
  name     = "tg-register"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}
 
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_home.arn
  }
}
 
resource "aws_lb_listener_rule" "images_rule" {
  listener_arn = aws_lb_listener.app_listener.arn
  priority     = 100
 
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_images.arn
  }
 
  condition {
    path_pattern {
      values = ["/images"]
    }
  }
}
 
resource "aws_lb_listener_rule" "register_rule" {
  listener_arn = aws_lb_listener.app_listener.arn
  priority     = 200
 
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_register.arn
  }
 
  condition {
    path_pattern {
      values = ["/register"]
    }
  }
}
 
resource "aws_instance" "home" {
  ami                         = "ami-0900588ae829985de"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_a.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.alb_sg.id]
  key_name                    = var.key_name
 
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              echo "Welcome to Home Page" > /var/www/html/index.html
              systemctl restart nginx
              EOF
 
  tags = {
    Name = "instance-a-home"
  }
}
 
resource "aws_instance" "images" {
  ami                         = "ami-0900588ae829985de"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_b.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.alb_sg.id]
  key_name                    = var.key_name
 
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              mkdir -p /var/www/html
              echo "This is the Images Page" > /var/www/html/index.html
              systemctl restart nginx
EOF
 
 
  tags = {
    Name = "instance-b-images"
  }
}
 
resource "aws_instance" "register" {
  ami                         = "ami-0900588ae829985de"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.subnet_c.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.alb_sg.id]
  key_name                    = var.key_name
 
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              mkdir -p /var/www/html/register
              echo "Register Here!" > /var/www/html/register/index.html
              systemctl restart nginx
EOF
 
 
  tags = {
    Name = "instance-c-register"
  }
}
 
resource "aws_lb_target_group_attachment" "home_attachment" {
  target_group_arn = aws_lb_target_group.tg_home.arn
  target_id        = aws_instance.home.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "images_attachment" {
  target_group_arn = aws_lb_target_group.tg_images.arn
  target_id        = aws_instance.images.id
  port             = 80
}
 
resource "aws_lb_target_group_attachment" "register_attachment" {
  target_group_arn = aws_lb_target_group.tg_register.arn
  target_id        = aws_instance.register.id
  port             = 80
}
