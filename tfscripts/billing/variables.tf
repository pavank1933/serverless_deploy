variable "role_arn" {}
variable "aws_account_id" {}
variable "aws_region" {}
variable "ecr_repo" {}
variable "ec2_keypair_name" {}
variable "ami_nat_instance" {}
variable "tag_aws_env" {}
# variable "artifact_version" {}

variable "vpc_cidr" {
  description = "CIDR for the whole VPC"
  default = "10.0.0.0/16"
}
variable "public_subnet_cidr" {
  description = "CIDR for the Public Subnet"
  default = "10.0.0.0/24"
}
variable "db_password" {
  description = "PG rds password"
  default = "password"
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