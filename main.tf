###########################
# NAT INSTANCE
###########################
resource "aws_instance" "nat_instance" {
  ami               = var.nat-ami
  instance_type     = var.instance_type
  subnet_id         = aws_subnet.public[0].id
  key_name          = var.key_name
  security_groups   = [aws_security_group.nat_security_group.id]
  source_dest_check = false
  tags = {
    Name = "Bastion-Instance"
  }
}

##############################
# LAUNCH TEMPLATE
##############################

resource "aws_launch_template" "tf-lt" {
  name                   = "${var.name}-lt"
  instance_type          = var.instance_type
  image_id               = var.ubuntu_ami
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.EC2_security_group.id]
  user_data = file("userdata.sh")
  # user_data              = filebase64("./userdata.sh")
  depends_on = [
    github_repository_file.db_endpoint,
    aws_instance.nat_instance
  ]
  iam_instance_profile {
    name = aws_iam_instance_profile.instance-role.id
  }
  tags = {
    Name = "${var.name}-Instance"
  }
}

###########################
#  GİTHUB
###########################

resource "github_repository_file" "db_endpoint" {
  content             = aws_db_instance.rds-tf.address
  file                = "src/cblog/dbserver.endpoint"
  repository          = "AWS-Project"
  overwrite_on_create = true
  branch              = "main"
}

##################################
# CERTIFICATE MANAGER 
##################################

# # Find a certificate that is isssued

# data "aws_acm_certificate" "isssued" {
#   domain   = var.domain_name
#   statuses = ["ISSUED"]
# }

# # To use exist hosted zone 

# data "aws_route53_zone" "zone" {
#   name         = var.domain_name
#   private_zone = false
# }

#------------------------------------------------------------------------------
# If you want to create new cert and create cname record to your hosted zone,
# You can use this code bloks, i prefer to use my exist acm cert
#------------------------------------------------------------------------------- 

# resource "aws_acm_certificate" "cert" {
#   domain_name       = var.subdomain_name
#   validation_method = "DNS"
#   tags = {
#     "Name" = var.subdomain_name
#   }
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "cert_validation" {
#   depends_on      = [aws_acm_certificate.cert]
#   zone_id         = data.aws_route53_zone.zone.id
#   name            = sort(aws_acm_certificate.cert.domain_validation_options[*].resource_record_name)[0]
#   type            = "CNAME"
#   ttl             = "300"
#   records         = [sort(aws_acm_certificate.cert.domain_validation_options[*].resource_record_value)[0]]
#   allow_overwrite = true

# }

# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [
#     aws_route53_record.cert_validation.fqdn
#   ]
#   timeouts {
#     create = "60m"
#   }
# }

###############################
#  APPLICATION LOAD BALANCER
###############################

resource "aws_lb" "alb-tf" {
  name               = "${var.name}-tf"
  load_balancer_type = "application"
  internal           = false
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.ALB_security_group.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
  depends_on = [
    aws_launch_template.tf-lt
  ]
}


###############################
# LISTENER RULES
###############################

resource "aws_lb_listener" "tf-https" {
  load_balancer_arn = aws_lb.alb-tf.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.aws_acm_certificate_arn
  depends_on = [
    aws_lb.alb-tf
  ]
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf-target.arn
  }
  # depends_on = [
  #   aws_acm_certificate.cert
  # ]
}

resource "aws_lb_listener" "tf-http" {
  load_balancer_arn = aws_lb.alb-tf.arn
  port              = "80"
  protocol          = "HTTP"
  depends_on = [
    aws_lb.alb-tf
  ]
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


###############################
#  TARGET GROUP
##############################

resource "aws_lb_target_group" "tf-target" {
  name        = "${var.name}-target"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.aws_project.id

  health_check {
    protocol            = "HTTP"         # default HTTP
    port                = "traffic-port" # default
    unhealthy_threshold = 2              # default 3
    healthy_threshold   = 5              # default 3
    interval            = 20             # default 30
    timeout             = 5              # default 10
  }
}

################################
# AUTOSCALING GROUP AND POLICY
################################

resource "aws_autoscaling_group" "asg-tf" {
  name                      = "${var.name}-asg-tf"
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_lb_target_group.tf-target.arn]
  depends_on = [
    aws_instance.nat_instance,
    aws_lb.alb-tf
  ]
  vpc_zone_identifier = [for subnet in aws_subnet.private : subnet.id]
  launch_template {
    id      = aws_launch_template.tf-lt.id
    version = "$Default"
  }
}

resource "aws_autoscaling_policy" "policy-tf" {
  name                   = "${var.name}-asg-policy-tf"
  autoscaling_group_name = aws_autoscaling_group.asg-tf.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0
  }
}

#################################
#  CLOUDFRONT
################################
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.subdomain_name}"
}

resource "aws_cloudfront_distribution" "cf-tf" {

  origin {
    domain_name = aws_lb.alb-tf.dns_name
    origin_id   = aws_lb.alb-tf.id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_ssl_protocols     = ["TLSv1"]
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "match-viewer"
    }
  }

  price_class = "PriceClass_All"
  enabled     = true
  comment     = "Cloudfront Distribution pointing to ALBDNS"
  aliases     = [var.subdomain_name]
  depends_on = [
    aws_autoscaling_group.asg-tf
  ]


  default_cache_behavior {
    target_origin_id       = aws_lb.alb-tf.dns_name
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    max_ttl                = 86400
    default_ttl            = 3600
    smooth_streaming       = false
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Host", "Accept", "Accept-Charset", "Accept-Datetime", "Accept-Encoding", "Accept-Language", "Authorization", "Cloudfront-Forwarded-Proto", "Origin", "Referrer"]
    }
    compress = true
  }

  viewer_certificate {
    acm_certificate_arn            = var.aws_acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

####################################
# ROUTE 53 HEALTH CHECK
####################################

resource "aws_route53_health_check" "tf-health" {
  type             = "HTTP"
  port             = 80
  fqdn             = aws_cloudfront_distribution.cf-tf.domain_name
  request_interval = 30
  depends_on = [
    aws_cloudfront_distribution.cf-tf
  ]
  tags = {
    Name = "${var.subdomain_name}-healthcheck"
  }
}

# ##################################
# #  ROUTE 53 AND HOSTED ZONE
# ##################################


resource "aws_route53_record" "primary" {
  zone_id         = var.hosted_zone_id
  name            = var.domain_sub_name
  type            = "A"
  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.tf-health.id
  depends_on = [
    aws_route53_health_check.tf-health
  ]

  alias {
    name                   = aws_cloudfront_distribution.cf-tf.domain_name
    zone_id                = aws_cloudfront_distribution.cf-tf.hosted_zone_id
    evaluate_target_health = false
  }
  failover_routing_policy {
    type = "PRIMARY"
  }
}

resource "aws_route53_record" "secondary" {
  zone_id        = var.hosted_zone_id
  name           = var.domain_sub_name
  set_identifier = "Secondary"
  type           = "A"
  depends_on = [
    aws_cloudfront_distribution.cf-tf
  ]
  alias {
    name                   = aws_s3_bucket.failover_bucket.id             # "s3-website-us-east-1.amazonaws.com"
    zone_id                = aws_s3_bucket.failover_bucket.hosted_zone_id # "Z3AQBSTGFYJSTF"
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "SECONDARY"
  }
}

####################################
# LAMBDA ROLE AND POLICIES
###################################

resource "aws_iam_role" "iam_for_lambda" {
  name               = "lambda-role-for-s3"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda-s3-dynamodb" {
  name = "lambda-s3-dynamodb"
  role = aws_iam_role.iam_for_lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]

    Statement = [
      {
        Action = [
          "lambda:Invoke*"
        ]
        Effect   = "Allow"
        Resource = ["*"]
      }
    ]
    #-------------------------------------------------------
    # To create inline policy  we can use this code blocks
    #-------------------------------------------------------

    # Statement = [
    #   {
    #     Action = ["dynamodb:GetItem",
    #               "dynamodb:PutItem",
    #               "dynamodb:UpdateItem"
    #     ]
    #     Effect = "Allow"
    #     Resource = ["arn:aws:dynamodb:*:*:table/awscapstoneDynamo"]
    #   }
    # ]
  })
}

# data "aws_iam_policy_document" "lambda-s3-dynamodb" {
#   statement {
#     actions = ["s3:PutObject","s3:GetObject","s3:GetObjectVersion"]
#     resources = [ "*" ]
#   }

#   statement {
#     actions   = ["lambda:Invoke*"]
#     resources = [ "*" ]
#   }

#   statement {
#     actions = [ "dynamodb:GetItem",
#                 "dynamodb:PutItem",
#                 "dynamodb:UpdateItem"]
#     resources = [ "arn:aws:dynamodb:*:*:*" ]
#   }

#   statement {
#     actions = [ "s3:*",
#                 "s3-object-lambda:*"]
#     resources = [ "*" ]
#   }
# }

resource "aws_iam_role_policy_attachment" "role-policy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/job-function/NetworkAdministrator",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ])
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = each.value
}


##############################
# LAMBDA FUNCTION
#############################

data "archive_file" "zipit" {
  type        = "zip"
  source_file = "./lambda.py"
  output_path = "lambda.zip"
}

resource "aws_lambda_function" "lambda-tf" {
  filename         = "lambda.zip"
  source_code_hash = data.archive_file.zipit.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  runtime          = "python3.8"
  function_name    = "lambda-function"
  handler          = "index.handler"
  vpc_config {
    subnet_ids         = [aws_subnet.public[0].id, aws_subnet.public[1].id, aws_subnet.private[0].id, aws_subnet.private[1].id]
    security_group_ids = [aws_security_group.nat_security_group.id]
  }
}

resource "aws_lambda_permission" "lambda-invoke" {
  statement_id   = "AllowExecutionFromS3Bucket"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.lambda-tf.function_name
  source_arn     = aws_s3_bucket.website_bucket.arn
  source_account = var.awsAccount
  principal      = "s3.amazonaws.com"
    depends_on = [
    aws_s3_bucket.website_bucket
  ]
}


##############################
#  DYNAMODB TABLE
##############################

resource "aws_dynamodb_table" "dynamodb-tf" {
  name           = "${var.name}-Dynamo"
  hash_key       = "id"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  attribute {
    name = "id"
    type = "S"
  }
}



