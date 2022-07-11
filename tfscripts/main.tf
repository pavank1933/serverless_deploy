terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket         = "adserverx-tfstate-qa"
    key            = "states/terraform.tfstate"
    dynamodb_table = "app-state"
    region  = "us-east-1"
  }
}

# Configure the AWS Provider
provider "aws" {
    region 	 = var.aws_region
  assume_role {
    role_arn     = var.role_arn
  }
  default_tags {
    tags = {
      Application = "adserver-x"
      Environment = var.tag_aws_env
      Version = "${var.artifact_version}"
      Monitor       = "${var.tag_aws_env == "adserverx-prod" ? "YES" : "NO"}"
    }
  }
}

# resource "aws_s3_bucket" "adserverx_remote_tfstate" {
#  bucket        = "adserverx_remote_tfstate"
#  acl           = "private"
#  force_destroy = true
#  server_side_encryption_configuration {
#    rule {
#      apply_server_side_encryption_by_default {
#        kms_master_key_id = aws_kms_key.adserverx_kms_master_key.arn
#        sse_algorithm     = "aws:kms"
#      }
#    }
#  }

#  versioning {
#    enabled = true
#  }

#  lifecycle_rule {
#    enabled = true
#    transition {
#      days          = 30
#      storage_class = "STANDARD_IA"
#    }
#    noncurrent_version_transition {
#      days          = 30
#      storage_class = "STANDARD_IA"
#    }
#  }

#  tags = {
#      Name = "adserverx_S3_tfstate_Bucket1"
#      Role = "adserverx S3 Tfstate Bucket"
#  }
# }

# resource "aws_s3_bucket_object" "adserverx-s3-bucket-key-remote_tfstate" {
#    bucket  = aws_s3_bucket.adserverx_remote_tfstate.id
#    acl     = "private"
#    key     =  "tfstate/adserverx/terraform.tfstate"
#    kms_key_id = "${aws_kms_key.adserverx_kms_master_key.arn}"
# }

# terraform {
#   backend "s3" {
#     region = "us-east-1"
#     bucket = "adserverx_remote_tfstate"
#     key    = "tfstate/adserverx/terraform.tfstate"
#   }
# }

#use this somewhere to utlilize above backend state
# data "terraform_remote_state" "adserverx_tfstate" {
#   backend = "s3"
#   config = {
#     region = var.aws_region
#     bucket = "adserverx_remote_tfstate"
#     key    = "tfstate/adserverx/terraform.tfstate"
#   }
# }

# module "vpc" {
#   source = "./vpc"
  
#   aws_region         = var.aws_region
#   vpc_cidr = var.vpc_cidr
#   ami_nat_instance = var.ami_nat_instance
#   ec2_keypair_name = var.ec2_keypair_name
#   subnet_cidrs_private = var.subnet_cidrs_private
#   availability_zones = var.availability_zones
#   public_subnet_cidr = var.public_subnet_cidr
#   #private_subnet_ids = var.private_subnet_ids
# }










resource "aws_vpc" "adserverx_vpc" {
 cidr_block = "${var.vpc_cidr}"
 enable_dns_hostnames = true
 tags = {
     Name = "adserverx_vpc1"
     Role = "adserverx vpc1"
 }
}

output "vpc_id" {
 value = "${aws_vpc.adserverx_vpc.id}"
}

resource "aws_security_group" "adserverx_aws_nat_sg" {
 name = "adserverx_nat_sg"
 description = "Allow traffic to pass from the private subnet to the internet"
 ingress {
   from_port = 80
   to_port = 80
   protocol = "tcp"
   cidr_blocks = ["${var.subnet_cidrs_private[0]}"]
 }
 ingress {
   from_port = 443
   to_port = 443
   protocol = "tcp"
   cidr_blocks = ["${var.subnet_cidrs_private[0]}"]
 }
 ingress {
   from_port = 5432
   to_port = 5432
   protocol = "tcp"
   cidr_blocks = ["${var.subnet_cidrs_private[0]}"]
 }
 ingress {
   from_port = -1
   to_port = -1
   protocol = "icmp"
   cidr_blocks = ["${var.subnet_cidrs_private[0]}"]
 }
 egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
 vpc_id = "${aws_vpc.adserverx_vpc.id}"
 tags = {
     Name = "adserverx_aws_nat_sg1"
     Role = "ADserverx NAT Security Group1"
 }
}
output "nat_sg_id" {
 value = "${aws_security_group.adserverx_aws_nat_sg.id}"
}

resource "aws_internet_gateway" "adserverx_igw" {
 vpc_id = "${aws_vpc.adserverx_vpc.id}"
 tags = {
     Name = "adserverx_igw1"
     Role = "adserverx igw1"
 }
 lifecycle {
    #prevent_destroy = true
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

#
# NAT Instance
#
resource "aws_instance" "adserverx_nat" {
 ami = "${var.ami_nat_instance}" # this is a special ami preconfigured to do NAT
 availability_zone = "us-east-1a"
 instance_type = "t2.micro"
 key_name = "${var.ec2_keypair_name}"
 security_groups = ["${aws_security_group.adserverx_aws_nat_sg.id}"]
 subnet_id = "${aws_subnet.adserverx_public_subnet.id}"
 associate_public_ip_address = true
 source_dest_check = false
 tags = {
     Name = "adserverx_nat_instance1"
     Role = "adserverx nat instance1"
 }
 lifecycle {
   #prevent_destroy = true
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      tags,
    ]
  }
}

resource "aws_eip" "adserverx_nat_eip" {
 instance = "${aws_instance.adserverx_nat.id}"
 vpc = true
 tags = {
     Name = "adserverx_nat_eip1"
     Role = "adserverx nat eip1"
 }
}

#
# Public Subnets
#
resource "aws_subnet" "adserverx_public_subnet" {
 vpc_id = "${aws_vpc.adserverx_vpc.id}"
 cidr_block = "${var.public_subnet_cidr}"
 availability_zone = "us-east-1a"
 tags = {
     Name = "adserverx_public_subnet1"
     Role = "adserverx public subnet1"
 }
}
output "public_subnet_id" {
 value = "${aws_subnet.adserverx_public_subnet.id}"
}

resource "aws_route_table" "adserverx_public_route" {
 vpc_id = "${aws_vpc.adserverx_vpc.id}"
 route {
     cidr_block = "0.0.0.0/0"
     gateway_id = "${aws_internet_gateway.adserverx_igw.id}"
 }
 tags = {
     Name = "adserverx_public_subnet_route_table1"
     Role = "adserverx public subnet route table1"
 }
}

output "adserverx_public_route_table" {
 value = "${aws_route_table.adserverx_public_route.id}"
}

resource "aws_route_table_association" "adserverx_public_subnet_rtable_assoc" {
 subnet_id = "${aws_subnet.adserverx_public_subnet.id}"
 route_table_id = "${aws_route_table.adserverx_public_route.id}"
}

#
# Private Subnet
#
resource "aws_subnet" "adserverx_private_subnet" {
 count = "${length(var.subnet_cidrs_private)}"
 vpc_id = "${aws_vpc.adserverx_vpc.id}"
 cidr_block = "${var.subnet_cidrs_private[count.index]}"
 availability_zone = "${var.availability_zones[count.index]}"
 tags = {
     Name = "adserverx_private_subnet1"
     Role = "adserverx private subnet1"
 }
}

output "private_subnet_ids" {
  value = [aws_subnet.adserverx_private_subnet[*].id]
}

resource "aws_route_table" "adserverx_private_route_table" {
 vpc_id = "${aws_vpc.adserverx_vpc.id}"
 route {
     cidr_block = "0.0.0.0/0"
     instance_id = "${aws_instance.adserverx_nat.id}"
 }
 tags = {
     Name = "adserverx_private_subnet_route_table1"
     Role = "adserverx private subnet route table1"
 }
}

output "adserverx_private_route_table" {
  value = "${aws_route_table.adserverx_private_route_table.id}"
}

resource "aws_route_table_association" "adserverx_private_route_table_assoc_1" {
 subnet_id = "${aws_subnet.adserverx_private_subnet[0].id}"
 route_table_id = "${aws_route_table.adserverx_private_route_table.id}"
 depends_on = [aws_route_table.adserverx_private_route_table]
}

resource "aws_route_table_association" "adserverx_private_route_table_assoc_2" {
 subnet_id = "${aws_subnet.adserverx_private_subnet[1].id}"
 route_table_id = "${aws_route_table.adserverx_private_route_table.id}"
 depends_on = [aws_route_table.adserverx_private_route_table]
}

resource "aws_security_group" "adserverx_vpc_security_group1" {
 name = "adserverx_vpc_security_group1"
 description = "Allow traffic to pass from the private subnet to the internet"
 ingress {
   from_port = 443
   to_port = 443
   protocol = "tcp"
   cidr_blocks = ["${var.subnet_cidrs_private[0]}","${var.subnet_cidrs_private[1]}","${var.public_subnet_cidr}"]
 }
 ingress {
   from_port = 6379
   to_port = 6379
   protocol = "tcp"
   cidr_blocks = ["${var.subnet_cidrs_private[0]}","${var.subnet_cidrs_private[1]}","${var.public_subnet_cidr}"]
 }
 egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
 #vpc_id      = "${module.vpc.vpc_id}"
 vpc_id      = "${aws_vpc.adserverx_vpc.id}"
 tags = {
     Name = "adserverx-vpc-security-group1"
     Role = "adserverx vpc security group1"
 }
}
output "adserverx_vpc_security_group1" {
 value = "${aws_security_group.adserverx_vpc_security_group1.id}"
}



resource "aws_iam_role" "adserverx_iam_lambda_role" {
    name                 = "adserverx_iam_lambda_role"
    assume_role_policy = jsonencode(
    {
      "Statement": [
        {
          "Action": "sts:AssumeRole", 
          "Effect": "Allow", 
          "Principal": {
            "Service": [
              "lambda.amazonaws.com"
            ]
          }, 
          "Sid": ""
        }
      ], 
      "Version": "2012-10-17"
    })
    tags = {
      Name = "adserverx_iam_lambda_role1"
      Role = "adserverx iam lambda role"
  }
}

resource "aws_iam_policy" "adserverx_iam_lambda_role_policy" {
    depends_on           = [ aws_iam_role.adserverx_iam_lambda_role ]
    policy = <<EOF
{
  "Statement": [

    {
      "Action": [
        "sqs:*"
      ], 
      "Effect": "Allow", 
      "Resource": [
        "*"
      ]
    },
    {
      "Action": [
        "kms:*"
      ], 
      "Effect": "Allow", 
      "Resource": [
        "*"
      ]
    }, 
    {
      "Action": [
        "logs:*"
      ], 
      "Effect": "Allow", 
      "Resource": [
        "*"
      ]
    }, 
    {
      "Action": [
        "apigateway:*"
      ], 
      "Effect": "Allow", 
      "Resource": [
        "*"
      ]
    },

    {
      "Action": [
        "s3:*"
      ], 
      "Effect": "Allow", 
      "Resource": [
        "*"
      ]
    }, 

    {
      "Action": [
        "ec2:*"
      ], 
      "Effect": "Allow", 
      "Resource": [
        "*"
      ]
    },

    {
      "Action": [
        "elasticache:*"
      ], 
      "Effect": "Allow", 
      "Resource": [
        "*"
      ]
    }
    
  ], 
  "Version": "2012-10-17"
}
EOF
    name                 = "adserverx_iam_lambda_role_policy"

    tags = {
      Name = "adserverx_iam_lambda_role_policy1"
      Role = "adserverx iam role policy"
  }
}

resource "aws_iam_role_policy_attachment" "adserverx_iam_lambda_role_policy_attach" {
  role       = aws_iam_role.adserverx_iam_lambda_role.name
  policy_arn = aws_iam_policy.adserverx_iam_lambda_role_policy.arn
}

module "adserverx_apigw" {
  source = "./adserverx_apigw"
  
  aws_region         = var.aws_region
  aws_account_id         = var.aws_account_id
  ecr_repo         = var.ecr_repo
  #artifact_version          = var.artifact_version
  aws_iam_lambda_role_arn = aws_iam_role.adserverx_iam_lambda_role.arn
  aws_iam_lambda_role_name = aws_iam_role.adserverx_iam_lambda_role.name

  #aws_lambda_subnets = ["${module.vpc.private_subnet_ids[*]}","${module.vpc.public_subnet_id}"]
  #aws_lambda_subnets = "${module.vpc.private_subnet_ids[*]}"
  #aws_lambda_subnets = ["${module.vpc.private_subnet_ids[0]}","${module.vpc.private_subnet_ids[1]}","${module.vpc.public_subnet_id}"]
  #aws_lambda_subnets         = ["${module.vpc.public_subnet_id}","${module.vpc.adserverx_private_first_subnet_output}","${module.vpc.adserverx_private_second_subnet_output}"]
  #aws_lambda_subnets         = ["${aws_subnet.adserverx_private_subnet.*.id}","${aws_subnet.adserverx_public_subnet.id}"]
  aws_lambda_subnets         = ["${aws_subnet.adserverx_public_subnet.id}"]
  #aws_lambda_subnets         = ["${aws_subnet.adserverx_private_subnet[0].id}","${aws_subnet.adserverx_private_subnet[1].id}","${aws_subnet.adserverx_public_subnet.id}"]
  
  
  #aws_lambda_subnets         = ["${aws_subnet.adserverx_private_subnet.*.id}","${aws_subnet.adserverx_public_subnet.id}"]
  aws_lambda_sg = aws_security_group.adserverx_vpc_security_group1.id

  #depends_on = [aws_subnet.adserverx_public_subnet, aws_subnet.adserverx_private_subnet]
}