#first we need to create a security group 

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh all inbound traffic and all outbound traffic"
  #vpc will be default 

  tags = {
    Name = "allow_ssh"
    CreatedBy =  "Harish"
    
  }
}
resource "aws_security_group" "allow_all_traffic" {
  # ... other configuration ...
ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
      }
  ingress {
    from_port        = 8081
    to_port          = 8081
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
      }
  ingress {
    from_port        = 9000
    to_port          = 9000
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
      }
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
      }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
      }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
      }
}


module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-tf"

  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.allow_all_traffic.id] #replace your SG
  subnet_id = aws_default_subnet.default_az1.id #replace your Subnet
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins.sh")
  tags = {
    Name = "jenkins-tf"
  }
}
module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type          = "t3.small"
  vpc_security_group_ids = [aws_security_group.allow_all_traffic.id]
  # convert StringList to list and get first element
  subnet_id = aws_default_subnet.default_az1.id
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins-agent.sh")
  tags = {
    Name = "jenkins-agent"
  }
}

resource "aws_key_pair" "tools_pub"{
  key_name   = "tools_nexus"
  #public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAaoyW5Sw4JsvbTpRgIPO1ZUBGtB30TdDklkCMTgIdxaReXQbLs+TjTr23tx1m8tRuiPqSb52U8TN+5D0KMScM9mplKUZR1shLV0EaUiPjWEGAgKltaMVoiNz9dAG8AiflWzUUD5upKneKEron4+BDVKcD/Raf/CWU7du865zC/NHeEqkEyKQnZEJA6lHGWt6lMuj7OuQJzrCtjIUBlOUWpfVc0b4rEOlCqh/LdfkZAWbS07QHZpAAbBcVWZIFqYOzV5QPFFVb0BhAYUxRDFlJ7gcZFfBmjtPB9I6s0SeufXutVDgplz72381m3EE3J+w+IzLPMAiCxLfWV0C+PHHhYVCxN0K/yWexENrfJry6wekUR27mwQvDZDGFE5RWo+d22SccuWYmYtjw6LdpNV9P96ZhT14IicGOTdsGKksJ5aG+f+ogsYuN12Fgf7wBMCeu2hB26vF0SfV6lP3hUEIo4ycjMNBBH4bisiM+//2PXwMjCTMCkXmPSOoioKB63jM= Harish@DESKTOP-TSJOBG3"
   public_key = file("~/.ssh/tools.pub")
}


module "nexus" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "nexus"

  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.allow_all_traffic.id]
  # convert StringList to list and get first element
  subnet_id = aws_default_subnet.default_az1.id
  ami = data.aws_ami.nexus_ami_info.id
  key_name = aws_key_pair.tools_pub.key_name
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30
    }
  ]
  tags = {
    Name = "nexus"
  }
}



module "sonarqube" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "Sonar-qube"

  instance_type          = "t3.medium"
  vpc_security_group_ids = [aws_security_group.allow_all_traffic.id]
  # convert StringList to list and get first element
  subnet_id = aws_default_subnet.default_az1.id
  ami = data.aws_ami.Sonarqube_ami_info.id
  key_name = aws_key_pair.tools_pub.key_name
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30
    }
  ]
  tags = {
    Name = "Sonar-qube"
  }
}


resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"

  tags = {
    Name = "Default subnet for us-east-1a"
  }
}


module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins-master"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins.public_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins_agent.public_ip
      
      ]
      allow_overwrite = true
    },
    {
      name    = "nexus"
      type    = "A"
      ttl     = 1
      allow_overwrite = true
      records = [
        module.nexus.public_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "sonarqube"
      type    = "A"
      ttl     = 1
      allow_overwrite = true
      records = [
        module.sonarqube.public_ip
      ]
      allow_overwrite = true
    }
  ]

}