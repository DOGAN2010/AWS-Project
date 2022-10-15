##########################################
# IAM ROLE FOR EC2-FIRST S3 FULL ACCESS
##########################################

resource "aws_iam_role" "ec2-s3" {
  name = "ec2-s3-full-tf"
  path = "/"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "ec2.amazonaws.com"
        },
        "Action" = "sts:AssumeRole"
        "Sid"    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3-full" {
  name = "s3-full-tf"
  role = aws_iam_role.ec2-s3.id
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "s3:*",
          "s3-object-lambda:*"
        ],
        "Resource" = "*"
      }
    ]
  })
}

#############################
# IAM INSTANCE PROFILE
############################

resource "aws_iam_instance_profile" "instance-role" {
  name = "instance-role"
  role = aws_iam_role.ec2-s3.name
}

