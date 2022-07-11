terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
    region   = var.aws_region
  assume_role {
    role_arn     = var.role_arn
  }
  default_tags {
    tags = {
      Application = "adserver-x"
      Environment = var.tag_aws_env
      Monitor       = "${var.tag_aws_env == "adserverx-prod" ? "YES" : "NO"}"
    }
  }
}

locals {
  lambda_names = ["ads", "connectivity", "ip-exclusion", "phov", "media-info", "processS3File", "processSQSS3FileEvent", "writeEventToSQS", "handleFileProcessingStatus"]
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

resource "aws_lambda_function" "adserverx_lambda" {
  #count = "${length(local.lambda_names)}"
  for_each   = toset(local.lambda_names)
  function_name = "adserverx_${each.key}_lambda"
  #function_name = "adserverx_${element(local.lambda_names,count.index)}_lambda"
  
  role         = aws_iam_role.adserverx_iam_lambda_role.arn
  package_type = "Image"
  image_uri =  format("%s.dkr.ecr.%s.amazonaws.com/%s:adserver-latest",var.aws_account_id,var.aws_region,var.ecr_repo)
  timeout      = 300

  tags = {
      Name = "adserverx_${each.key}_lambda1"
      Role = "adserverx ${each.key} lambda"
      /*
      Name = "adserverx_${element(local.lambda_names,count.index)}_lambda1"
      Role = "adserverx ${element(local.lambda_names,count.index)} lambda"
      */
  }
}