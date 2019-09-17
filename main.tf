provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

variable "vpc_id" {
  default = "vpc-189e7471"
}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_route53_zone" "onalabs" {
  name = "onalabs.org."
}

resource "aws_route53_record" "example" {
  zone_id = data.aws_route53_zone.onalabs.zone_id
  name = "botieno.${data.aws_route53_zone.onalabs.name}"
  type = "A"
  ttl = "300"
  records = [aws_instance.webserver.public_ip]
}

resource "aws_security_group" "default" {
  name        = "botieno-allow-ssh"
  description = "Allow inbound and outbound traffic"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "botieno-deployer"
  public_key = templatefile("~/.ssh/id_rsa.pub", {})
}

resource "aws_instance" "webserver" {
  ami             = "ami-05c1fa8df71875112"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.default.name]
  user_data       = templatefile("init.sh.tpl", {})
  key_name        = aws_key_pair.deployer.key_name
  tags = {
    Name = "botieno"
    App  = "master-class"
  }
}
