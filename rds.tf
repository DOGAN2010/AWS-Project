resource "aws_db_subnet_group" "RDS_subnet_group" {
  name        = "main_subnet_group"
  description = "Our main group of subnets"
  subnet_ids  = ["${aws_subnet.private[0].id}", "${aws_subnet.private[1].id}"]
  tags = {
    Name = "rds_subnet_group"
  }
}
resource "aws_db_instance" "rds-tf" {
  depends_on                  = [aws_security_group.RDS_security_group]
  identifier                  = var.identifier
  allocated_storage           = var.storage
  max_allocated_storage       = var.max_storage
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  db_name                     = var.db_name
  username                    = var.username
  password                    = var.password
  port                        = var.rds_port
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  vpc_security_group_ids      = ["${aws_security_group.RDS_security_group.id}"]
  db_subnet_group_name        = aws_db_subnet_group.RDS_subnet_group.id
  skip_final_snapshot         = "true"
  #  final_snapshot_identifier = "false"
  tags = {
    Name = "aws-project-rds"
  }
}

