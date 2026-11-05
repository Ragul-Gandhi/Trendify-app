
provider "aws" {
    region = "ap-south-1"  
}

  
#variables for ami and instance type
variable "ami" {
    description = "AMI ID for the EC2 instance"
    type        = string
    default     = "ami-094adff9b24048c5c" 
}

variable "instance_type" {
    description = "Instance type for the EC2 instance"
    type        = string
    default     = "m7i-flex.large"  # Change this to your desired instance type
}


# Defining VPC for the EC2 instance

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "main-vpc"
    }
}

resource "aws_subnet" "main" {
    vpc_id     = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "main-subnet"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "main-igw"
    }
}

resource "aws_route_table" "main" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
}

resource "aws_route_table_association" "main" {
    subnet_id      = aws_subnet.main.id
    route_table_id = aws_route_table.main.id
}

resource "tls_private_key" "main" {
    algorithm = "RSA"
    rsa_bits  = 4096
}

resource "aws_key_pair" "main" {
    key_name   = "main-key"
    public_key = tls_private_key.main.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
    filename = "${path.module}/main-key.pem"
    content  = tls_private_key.main.private_key_pem
    file_permission = "0400"
}


# Defining Security Group for the EC2 instance
resource "aws_security_group" "main" {
    name        = "main-sg"
    description = "Allow SSH and HTTP"
    vpc_id      = aws_vpc.main.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}


# Defining the EC2 instance
resource "aws_instance" "main" {
    ami           = var.ami
    instance_type = var.instance_type
    subnet_id     = aws_subnet.main.id
    vpc_security_group_ids = [aws_security_group.main.id]
    key_name     = aws_key_pair.main.key_name
    tags = {
        Name = "main-instance"
    }

    user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                sudo systemctl enable nginx
                sudo apt install docker.io -y
                sudo systemctl start docker
                sudo systemctl enable docker
                sudo usermod -aG docker ubuntu
                
                
            EOF

    provisioner "remote-exec" {
    inline = [
        "cloud-init status --wait",
        "sudo apt install fontconfig openjdk-21-jre -y",
        "sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key",
        "echo 'deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
        "sudo apt-get update -y",
        "sudo apt-get install jenkins -y",
        "sudo systemctl start jenkins",
        "sudo systemctl enable jenkins",    
        "sudo usermod -aG docker jenkins",
        "sudo systemctl restart jenkins",
    ]

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = tls_private_key.main.private_key_pem
        host        = aws_instance.main.public_ip
    }
}
}

