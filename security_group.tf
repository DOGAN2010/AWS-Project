##########################
# BASTION SEC GROUP
##########################

resource "aws_security_group" "nat_security_group" {
  name        = "nat_instance_security_group"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.aws_project.id

  dynamic "ingress" {
    for_each = var.secgr-nat-dynamic-ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = true
    }
  }

  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
}


##########################
# ALB SECURITY GROUP
##########################

resource "aws_security_group" "ALB_security_group" {
  name        = "ALB_security_group"
  description = "Application Load Balancer should be placed within a security group which allows HTTP (80) and HTTPS (443) connections from anywhere. "
  vpc_id      = aws_vpc.aws_project.id

  dynamic "ingress" {
    for_each = var.secgr-ALB-dynamic-ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = true
    }
  }

  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
}

############################
# EC2 SECURITY GROUP
############################

resource "aws_security_group" "EC2_security_group" {
  name        = "EC2_security_group"
  description = "EC2 should be placed within a security group which allows HTTP (80) and HTTPS (443) connections from anywhere. "
  vpc_id      = aws_vpc.aws_project.id
  depends_on = [
    aws_security_group.ALB_security_group
  ]
  dynamic "ingress" {
    for_each = var.secgr-EC2-dynamic-ports
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.ALB_security_group.id]
      self            = true
    }
  }
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  # ingress {
  #   from_port   = 443
  #   protocol    = "tcp"
  #   to_port     = 443
  #   cidr_blocks = [ aws_security_group.ALB_security_group.id ]
  # }
  # ingress {
  #   from_port   = 80
  #   protocol    = "tcp"
  #   to_port     = 80
  #   cidr_blocks = [ aws_security_group.ALB_security_group.id ]
  #   security_groups = [ aws_security_group.ALB_security_group.id ]
  # }
  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
}

##########################
#  RDS SECURITY GROUP
##########################

resource "aws_security_group" "RDS_security_group" {
  name        = "RDS_security_group"
  description = "Security group for RDS. "
  vpc_id      = aws_vpc.aws_project.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.EC2_security_group.id]
    self            = true
  }
  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
}
