########################
#  Blog Website's S3 Bucket
# Bucket creation
########################

resource "aws_s3_bucket" "website_bucket" {
  bucket = var.website_bucket_name
  #  acl    = "public-read"
  depends_on = [
    aws_lambda_function.lambda-tf
  ]
  tags = {
    Name        = "${var.bucket_tags}"
    Environment = "Dev"
  }
}
resource "aws_s3_bucket_policy" "website_bucket_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = file("policy/policys3lambda.json")
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.website_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda-tf.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix       = "media/"
  }

  depends_on = [
    aws_lambda_permission.lambda-invoke
  ]
}
# Public access configuration for S3 bucket
resource "aws_s3_bucket_public_access_block" "website_bucket_access" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Configuration for S3 static website hosting
resource "aws_s3_bucket_website_configuration" "bucket_website_configuration" {
  bucket = aws_s3_bucket.website_bucket.bucket

  redirect_all_requests_to {
    host_name = var.redirect_host_name
    protocol  = var.redirect_protocol
  }
}
##########################
# Bucket public access
##########################
resource "aws_s3_bucket_acl" "website_bucket_acl" {
  bucket = aws_s3_bucket.website_bucket.id
  acl    = "public-read"
}
resource "aws_s3_bucket_versioning" "website__bucket_versioning" {
  bucket = aws_s3_bucket.website_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

########################
# S3 Bucket for failover scenario
# Bucket creation
########################

resource "aws_s3_bucket" "failover_bucket" {
  bucket = var.failover_bucket_name
  #  acl    = "public-read"
  # website {
  #   index_document = "index.html"
  #   error_document = "index.html"
  # }

  tags = {
    Name        = "${var.bucket_tag}"
    Environment = "Dev"
  }
}
resource "aws_s3_bucket_policy" "failover_bucket_policy" {
  bucket = aws_s3_bucket.failover_bucket.id
  policy = file("policy/policy.json")
}
# Public access configuration for S3 bucket
resource "aws_s3_bucket_public_access_block" "failover_bucket_access" {
  bucket = aws_s3_bucket.failover_bucket.id

  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# Configuration for S3 static website hosting
resource "aws_s3_bucket_website_configuration" "bucket_failover_configuration" {
  bucket = aws_s3_bucket.failover_bucket.bucket
  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }

  #   redirect_all_requests_to {
  #     host_name = var.redirect_host_names
  #     protocol  = var.redirect_protocoll
  #   }
}
##########################
# Bucket public access
##########################
resource "aws_s3_bucket_acl" "failover_bucket_acl" {
  bucket = aws_s3_bucket.failover_bucket.id
  acl    = "public-read"
}
resource "aws_s3_bucket_versioning" "failover_bucket_versioning" {
  bucket = aws_s3_bucket.failover_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_object" "sorry" {
  bucket       = aws_s3_bucket.failover_bucket.id
  key          = "sorry.jpg"
  source       = "html/sorry.jpg"
  content_type = "text/html"
  etag         = filemd5("html/sorry.jpg")
  acl          = "public-read"
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.failover_bucket.id
  key          = "index.html"
  source       = "html/index.html"
  content_type = "text/html"
  etag         = md5(file("html/index.html"))
  acl          = "public-read"
}

# Set outputs
output "bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.bucket_website_configuration.website_endpoint
}

output "bucket_hosted_zone_id" {
  value = aws_s3_bucket.website_bucket.hosted_zone_id
}
# Set outputs
output "failover_bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.bucket_failover_configuration.website_endpoint
}

output "failover_bucket_hosted_zone_id" {
  value = aws_s3_bucket.failover_bucket.hosted_zone_id
}