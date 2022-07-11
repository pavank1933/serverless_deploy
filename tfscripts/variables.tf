variable "role_arn" {}
variable "aws_account_id" {}
variable "aws_region" {}
variable "ecr_repo" {}
variable "ec2_keypair_name" {}
variable "ami_nat_instance" {}
variable "tag_aws_env" {}
variable "aws_iam_lambda_role_arn" {
  default = ""
}

variable "artifact_version" {
  default = ""
}

variable "aws_iam_lambda_role_name" {
  default = ""
}
variable "aws_lambda_sg" {
    description = "AWS lambda SG"
    default = ""
}

variable "aws_lambda_subnets" {
    description = "AWS lambda subnets"
    default = ""
}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default = "10.0.0.0/16"
}
variable "public_subnet_cidr" {
  description = "CIDR for the Public Subnet"
  default = "10.0.0.0/24"
}
variable "subnet_cidrs_private" {
  default = {
    "0" = "10.0.10.0/24"
    "1" = "10.0.20.0/24"
  }
}

variable "availability_zones" {
  default = {
    "0" = "us-east-1a"
    "1" = "us-east-1b"
  }
}

#  variable "private_subnet_ids" {
#    type = list(string)
#    default = []
#  }