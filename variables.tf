variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "developer_name" {
  description = "Your name or handle. Used to name/tag/isolate your environment (e.g. \"alice\")."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type. t2.micro/t3.micro (depending on region) are AWS Free Tier eligible."
  type        = string
  default     = "t2.micro"
}

variable "app_port" {
  description = "Port the Flask app listens on"
  type        = number
  default     = 5000
}

variable "my_ip" {
  description = "Your public IP in CIDR form, e.g. \"203.0.113.5/32\". Find yours at https://checkip.amazonaws.com. Used to restrict SSH and app access to just you."
  type        = string
}
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}