# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Create a security group
resource "aws_security_group" "web_server" {
  name_prefix = "web_server"
  description = "Allow HTTP and HTTPS traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# Create an EC2 instance
resource "aws_instance" "web_server" {
  ami           = "ami-0dfcb1ef8550277af"
  instance_type = "t2.micro"

  # Associate the security group with the instance
  vpc_security_group_ids = [aws_security_group.web_server.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install -y nginx1.12
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF

  # Use a self-signed certificate for the web server
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # Redirect HTTP requests to HTTPS
  metadata_options.user_data = <<-EOF
                               #!/bin/bash
                               sudo sed -i 's/listen       80/listen       80 default_server/g' /etc/nginx/nginx.conf
                               sudo sed -i 's/# server_tokens off;/server_tokens off;/g' /etc/nginx/nginx.conf
                               sudo sed -i 's/# server_tokens off;/server_tokens off;/g' /etc/nginx/conf.d/default.conf
                               sudo service nginx restart
                               EOF
}

# Output the public IP address of the instance
output "public_ip" {
  value = aws_instance.web_server.public_ip
}
