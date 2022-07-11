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

resource "aws_iam_role" "adserverx_ads_rest_testiam_lambda_role" {
    name                 = "adserverx_ads_rest_testiam_lambda_role"
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
      Name = "adserverx_ads_rest_testiam_lambda_role1"
      Role = "adserverx iam lambda role"
  }
}


resource "aws_iam_policy" "adserverx_ads_rest_testiam_lambda_role_policy" {
    depends_on           = [ aws_iam_role.adserverx_ads_rest_testiam_lambda_role ]
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
    name                 = "adserverx_ads_rest_testiam_lambda_role_policy"

    tags = {
      Name = "adserverx_ads_rest_testiam_lambda_role_policy"
      Role = "adserverx iam role policy"
  }
}

resource "aws_iam_role_policy_attachment" "adserverx_ads_rest_testiam_lambda_role_policy_attach" {
  role       = aws_iam_role.adserverx_ads_rest_testiam_lambda_role.name
  policy_arn = aws_iam_policy.adserverx_ads_rest_testiam_lambda_role_policy.arn
}

resource "aws_lambda_function" "adserverx_rest_ads_test_lambda" {
  function_name = "adserverx_rest_ads_test_lambda"  
  role         = aws_iam_role.adserverx_ads_rest_testiam_lambda_role.arn
  package_type = "Image"
  image_uri =  format("%s.dkr.ecr.%s.amazonaws.com/%s:adserver-latest",var.aws_account_id,var.aws_region,var.ecr_repo)
  timeout      = 300

  # vpc_config {
  #     subnet_ids         = ["10.0.0.0/24","10.0.10.0/24","10.0.20.0/24"]
  #     security_group_ids = ["sg-0b827cb5a3c03a0dd"]
  #   }

  tags = {
      Name = "adserverx_rest_ads_test_lambda1"
      Role = "adserverx rest ads test lambda"
  }
}

resource "aws_api_gateway_rest_api" "adserverx_ads_rest_api_gateway" {
  name        = "adserverx_ads_rest_api_gateway"
  description = "adserverx ads rest api gateway"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
   tags = {
       Name = "adserverx_ads_rest_api_gateway1"
       Role = "adserverx ads rest api gateway"
   }
}

resource "aws_api_gateway_resource" "adserverx_ads_rest_api_gateway_proxy_resource" {
  rest_api_id = aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.id
  parent_id   = aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.root_resource_id
  path_part   = "{proxy+}" # activates proxy behavior, match any request path
}

# gateway_method which allows all HTTP request methods
resource "aws_api_gateway_method" "adserverx_ads_rest_api_gateway_proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.id
  resource_id   = aws_api_gateway_resource.adserverx_ads_rest_api_gateway_proxy_resource.id
  http_method   = "ANY"
  authorization = "NONE"
}

# integration which specifies how to route incoming requests for each method of API gateway resource
resource "aws_api_gateway_integration" "adserverx_ads_rest_api_gateway_proxy_integration" {
  rest_api_id = aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.id
  resource_id = aws_api_gateway_method.adserverx_ads_rest_api_gateway_proxy_method.resource_id
  http_method = aws_api_gateway_method.adserverx_ads_rest_api_gateway_proxy_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.adserverx_rest_ads_test_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "adserverx_ads_rest_api_gateway_deployment" {
   depends_on = [
     aws_api_gateway_integration.adserverx_ads_rest_api_gateway_proxy_integration
   ]

   rest_api_id = aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.id
   stage_name  = "staging"
}

resource "aws_lambda_permission" "adserverx_ads_rest_api_gateway_lambda_permission" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.adserverx_rest_ads_test_lambda.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.execution_arn}/*/*"
}