data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "dev-env" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "dev-env-${var.developer_name}-vpc"
  }
}
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.dev-env.id
  cidr_block               = var.public_subnet_cidr
  availability_zone        = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch  = true

  tags = {
    Name = "dev-env-${var.developer_name}-public-subnet"
  }
}
resource "aws_internet_gateway" "dev-env-igw" {
  vpc_id = aws_vpc.dev-env.id

  tags = {
    Name = "dev-env-${var.developer_name}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.dev-env.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev-env-igw.id
  }

  tags = {
    Name = "dev-env-${var.developer_name}-public-rt"
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "this" {
  key_name   = "dev-env-${var.developer_name}"
  public_key = tls_private_key.this.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.module}/dev-env-key.pem"
  file_permission = "0600"
}
resource "aws_security_group" "dev-env-sg" {
  name        = "dev-env-${var.developer_name}-sg"
  description = "SSH + Flask app access, restricted to my IP"
  vpc_id      = aws_vpc.dev-env.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "Flask app"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "dev_env_test" {
  ami                          = data.aws_ami.amazon_linux.id
  instance_type                = "t3.micro"
  key_name                     = aws_key_pair.this.key_name
  vpc_security_group_ids       = [aws_security_group.dev-env-sg.id]
  subnet_id                    = aws_subnet.public.id
  associate_public_ip_address  = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  depends_on = [aws_route_table_association.public]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.this.private_key_pem
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "app.py"
    destination = "/home/ec2-user/app.py"
  }

provisioner "remote-exec" {
  inline = [
    "sudo dnf install -y python3 python3-pip",
    "python3 -m pip install flask",
    "cd /home/ec2-user",
    "nohup python3 app.py > /home/ec2-user/app.log 2>&1 < /dev/null &",
    "sleep 5",
    "cat /home/ec2-user/app.log",
    "ps -ef | grep app.py | grep -v grep || true"
  ]
}
}