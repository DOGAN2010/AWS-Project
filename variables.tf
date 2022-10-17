variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "github_token" {
  description = "AWS region"
  type        = string
  default     = "XXXXXXXXXXXXXXXXXXXXXX"
}

variable "name" {
  type        = string
  description = "generic name"
  default     = "aws-project"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets_cidr" {
  type    = list(any)
  default = ["10.0.1.0/24", "10.0.4.0/24"]
}

variable "private_subnets_cidr" {
  type    = list(any)
  default = ["10.0.2.0/24", "10.0.5.0/24"]
}
variable "azs" {
  type    = list(any)
  default = ["us-east-1a", "us-east-1b"]
}
variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "karaca"
}
variable "secgr-nat-dynamic-ports" {
  default = ["22", "80", "443"]
}
variable "secgr-ALB-dynamic-ports" {
  default = ["80", "443"]
}
variable "secgr-EC2-dynamic-ports" {
  default = ["80", "443"]
}

variable "identifier" {
  default     = "database1" # "aws-capstone-rds"
  description = "Identifier for your DB"
}

variable "storage" {
  default     = "20"
  description = "Storage size in GB"
}

variable "max_storage" {
  default     = "40"
  description = "Storage size in GB"
}
variable "engine" {
  default     = "MySQL"
  description = "Engine type, here it is mysql"
}
variable "engine_version" {
  description = "Engine version"
  default     = "8.0.28"
}

variable "instance_class" {
  default     = "db.t2.micro"
  description = "Instance class"
}

variable "db_name" {
  default     = "database1"
  description = "db name"
}

variable "username" {
  default     = "admin"
  description = "User name"
}

variable "rds_port" {
  default     = "3306"
  description = "rds port"
}

variable "password" {
  description = "password, provide through your ENV variables"
  default     = "Clarusway1234"
}

variable "website_bucket_name" {
  type        = string
  description = "aws_dogan_blog"
  default     = "aws_dogan_blog"
}

variable "bucket_tags" {
  type        = string
  description = "Set key value tags for s3 bucket"
  default     = "aws_dogan_blog"
}

variable "block_public_acls" {
  type        = bool
  description = "Whether block public acl or not"
  default     = true
}

variable "block_public_policy" {
  type        = bool
  description = "Whether block public policy or not"
  default     = true
}

variable "ignore_public_acls" {
  type        = bool
  description = "Whether ignore public acls or not"
  default     = true
}

variable "restrict_public_buckets" {
  type        = bool
  description = "Whether restrict public buckets or not"
  default     = true
}

variable "redirect_host_name" {
  type        = string
  description = "Destination hostname for redirect request"
  default     = true
}

variable "redirect_protocol" {
  type        = string
  description = "Protocol use by redirect host"
  default     = "https"
}

variable "failover_bucket_name" {
  type        = string
  description = "awspr.dogandevops.clink"
  default     = "awspr.dogandevops.clink"
}
variable "bucket_tag" {
  type        = string
  description = "Set key value tags for s3 bucket"
  default     = "awspr.dogandevops.clink"
}
variable "redirect_host_names" {
  type        = string
  description = "Destination hostname for redirect request"
  default     = true
}

variable "redirect_protocoll" {
  type        = string
  description = "Protocol use by redirect host"
  default     = "https"
}
variable "hosted_zone_id" {
  type        = string
  description = "dogandevops.clink hosted zone ID"
  default     = "Z102278128A2ASDR3G41XFHYNZ" # Enter its unique ID for each zone hosted on Route53.
}
variable "ubuntu_ami" {
  default = "ami-0c09e99c7d9bb3ec3"
}

variable "nat-ami" {
  default = "ami-08c40ec9ead489470"
}


variable "domain_name" {
  default = "awspr.dogandevops.click" #  PLEASE ENTER YOUR DOMAİN NAME
} 

variable "subdomain_name" {
  default = "awspr.dogandevops.click" #  PLEASE ENTER YOUR FULL SUBDOMAİN NAME
}
variable "awsAccount" {
  default = "XXXXXXXXXXXXX" # PLEASE ENTER YOUR AWS ACCOUNT ID WİTHOUT '-'
}

# düzenle


variable "S3hostedzoneID" {
  default = "Z3AQBSTGZDFYJSTF"

}

variable "S3websiteendpoint" {
  default = "s3-website-us-east-1.amazonaws.com"
}

# host
#  ns-1394.awsdns-46.org.
# ns-1913.awsdns-47.co.uk.
# ns-390.awsdns-48.com.
# ns-682.awsdns-21.net.



# domain_name
#  serversThe name servers that respond to DNS queries for this domain.
# ns-542.awsdns-03.net
# ns-1268.awsdns-30.org
# ns-295.awsdns-36.com
# ns-1550.awsdns-01.co.uk

variable "aws_acm_certificate_arn" {
  default = "arn:aws:acm:us-east-1:9533970585235658:certificate/5e1a24a3-6388-4383-855d-f822bbd4db0f"

}
