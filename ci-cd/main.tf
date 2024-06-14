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


resource "aws_instance" "Jenkins_master" {
  ami           = data.aws_ami.ami_info.id
  instance_type = "t3.medium"
  vpc_security_group_ids = [aws_security_group.allow_all_traffic.id]
  user_data = file("jenkins.sh")

  tags = {
    Name = "Jenkins-master"
  }
}

resource "aws_instance" "jenkins_agent" {
  ami           = data.aws_ami.ami_info.id
  instance_type = "t3.medium"
  vpc_security_group_ids = [aws_security_group.allow_all_traffic.id]
 user_data = file("jenkins-agent.sh")
  tags = {
    Name = "Jenkins-agent"
  }
}


