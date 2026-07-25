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
    gateway_id = aws_internet_gateway.dev-env.id
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
resource "aws_instance" "server" {
  ami                    = "ami-0b6d9d3d33ba97d99"
  instance_type          = "t2.micro"
  key_name      = aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.webSg.id]
  subnet_id              = aws_subnet.sub1.id
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
      "sudo pip3 install flask",
      "nohup python3 /home/ec2-user/app.py &"
    ]
  }
}
