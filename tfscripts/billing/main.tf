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

resource "aws_iam_role" "adserverx_billing_beacon_iam_lambda_role" {
    name                 = "adserverx_billing_beacon_iam_lambda_role"
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
      Name = "adserverx_billing_beacon_iam_lambda_role1"
      Role = "adserverx billing beacon lambda role"
  }
}


resource "aws_iam_policy" "adserverx_billing_beacon_iam_lambda_role_policy" {
    depends_on           = [ aws_iam_role.adserverx_billing_beacon_iam_lambda_role ]
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
      "Effect": "Allow",
      "Action": "secretsmanager:*",
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
    name                 = "adserverx_billing_beacon_iam_lambda_role_policy"

    tags = {
      Name = "adserverx_billing_beacon_iam_lambda_role_policy1"
      Role = "adserverx billing beacon iam role policy"
  }
}

resource "aws_lambda_function" "adserverx_billing_beacon_lambda" {
  function_name = "adserverx_billing_beacon_lambda"  
  role         = aws_iam_role.adserverx_billing_beacon_iam_lambda_role.arn
  package_type = "Image"
  image_uri =  format("%s.dkr.ecr.%s.amazonaws.com/%s:adserver-latest",var.aws_account_id,var.aws_region,var.ecr_repo)
  timeout      = 300

  vpc_config {
      subnet_ids         = ["subnet-0727a9b7f293de7f6","subnet-0571d20b4875c2279","subnet-01c923eff4afe4343"]
      security_group_ids = ["sg-0ed1b54fac7509a3a"]
    }

  tags = {
      Name = "adserverx_billing_beacon_lambda1"
      Role = "adserverx billing beacon lambda"
      #Version = "${var.artifact_version}"
  }
}

resource "aws_iam_role_policy_attachment" "adserverx_billing_beacon_lambda_logs" {
  role       = aws_iam_role.adserverx_billing_beacon_iam_lambda_role.name
  policy_arn = aws_iam_policy.adserverx_billing_beacon_iam_lambda_role_policy.arn
}

resource "aws_lambda_permission" "adserverx_billing_beacon_allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.adserverx_billing_beacon_lambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.adserverx_billing_beacon_cloudwatch_log_group.arn}:*"
  qualifier     = aws_lambda_alias.adserverx_billing_beacon_lambda_alias.name
}

resource "aws_lambda_alias" "adserverx_billing_beacon_lambda_alias" {
  name             = "adserverx_billing_beacon_lambda_alias"
  description      = "adserverx_billing_beacon_lambda_alias"
  function_name    ="${aws_lambda_function.adserverx_billing_beacon_lambda.function_name}"
  function_version = "$LATEST"
}


resource "aws_apigatewayv2_api" "adserverx_billing_beacon_apigw_api" {
  name          = "adserverx_billing_beacon_apigw_api"
  protocol_type = "HTTP"
  tags = {
      Name = "adserverx_billing_beacon_apigw_api1"
      Role = "adserverx billing beacon apigw api"
  }
}

resource "aws_apigatewayv2_stage" "adserverx_billing_beacon_apigw_stage" {
  api_id = "${aws_apigatewayv2_api.adserverx_billing_beacon_apigw_api.id}"

  name        = "$default"
  auto_deploy = true

  # route_settings {
  #     route_key = "$adserverx_phov_lambda"
  #   } 

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.adserverx_billing_beacon_cloudwatch_log_group.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
  tags = {
      Name = "adserverx_billing_beacon_apigw_stage1"
      Role = "adserverx billing beacon stage"
  }
}

resource "aws_apigatewayv2_integration" "adserverx_billing_beacon_apigw_integration" {
    api_id = "${aws_apigatewayv2_api.adserverx_billing_beacon_apigw_api.id}"
    integration_type   = "AWS_PROXY"
    integration_method = "POST"
    integration_uri    = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:adserverx_billing_beacon_lambda/invocations"
}

resource "aws_apigatewayv2_route" "adserverx_billing_beacon_apigw_route" {
    api_id = "${aws_apigatewayv2_api.adserverx_billing_beacon_apigw_api.id}"
    #route_key = "ANY /adserverx_billing_beacon_apigw_stage"
    route_key = "ANY /adserverx_billing_beacon_lambda"
    #route_key = "$default"
    target    = "integrations/${aws_apigatewayv2_integration.adserverx_billing_beacon_apigw_integration.id}"
}

resource "aws_cloudwatch_log_group" "adserverx_billing_beacon_cloudwatch_log_group" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.adserverx_billing_beacon_apigw_api.name}"

  retention_in_days = 30
  tags = {
      Name = "adserverx_billing_beacon_cloudwatch_log_group1"
      Role = "adserverx billing beacon cloudwatch log group"
  }
}

resource "aws_lambda_permission" "adserverx_billing_beacon_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.adserverx_billing_beacon_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.adserverx_billing_beacon_apigw_api.execution_arn}/*/*"
}

resource "aws_lambda_function" "adserver_billing_sqsEventProcessor_lambda" {
  function_name = "adserver_billing_sqsEventProcessor_lambda"
  
  role         = aws_iam_role.adserverx_billing_beacon_iam_lambda_role.arn
  package_type = "Image"
  image_uri =  format("%s.dkr.ecr.%s.amazonaws.com/%s:adserver-latest",var.aws_account_id,var.aws_region,var.ecr_repo)
  timeout      = 300
  vpc_config {
      subnet_ids         = ["subnet-0727a9b7f293de7f6","subnet-0571d20b4875c2279","subnet-01c923eff4afe4343"]
      security_group_ids = ["sg-0ed1b54fac7509a3a"]
    }
  tags = {
      Name = "adserver_billing_sqsEventProcessor_lambda1"
      Role = "adserverx billing sqsEventProcessor lambda"
      #Version = "${var.artifact_version}" 
  }
  depends_on = [
    aws_iam_role_policy_attachment.adserverx_billing_beacon_lambda_logs,
    aws_cloudwatch_log_group.adserverx_billing_sqsEventProcessor_cloudwatch_log_group,
  ]
}

resource "aws_cloudwatch_log_group" "adserverx_billing_sqsEventProcessor_cloudwatch_log_group" {
  name = "/aws/api_gw/adserver_billing_sqsEventProcessor_lambda"

  retention_in_days = 30
  tags = {
      Name = "adserver_billing_sqsEventProcessor_lambda_cloudwatch_log_group1"
      Role = "adserver billing sqsEventProcessor lambda cloudwatch log group"
  }
}


resource "aws_sqs_queue" "adserverx_billing_sqs_queue" {
 name                  = "adserverx_billing_sqs_queue.fifo"
 visibility_timeout_seconds = "14400"
 fifo_queue            = true
 kms_master_key_id     = "alias/adserverx_kms_master_key_alias"
 content_based_deduplication = true
 deduplication_scope   = "queue"
 fifo_throughput_limit = "perQueue"
 tags = {
     Name = "adserverx_billing_sqs_queue1"
     Role = "adserverx billing sqs queue"
 }
}

output "adserverx_billing_sqs_queue_endpoint" {
  value       = aws_sqs_queue.adserverx_billing_sqs_queue.id
  description = "The endpoint of the adserverx billing sqs queue endpoint"
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = aws_sqs_queue.adserverx_billing_sqs_queue.arn
  function_name    = "${aws_lambda_function.adserver_billing_sqsEventProcessor_lambda.function_name}"
}

resource "aws_db_subnet_group" "adserverx_billing_rds_subnet_group" {
  name       = "adserverx_billing_rds_subnet_group"
  subnet_ids = ["subnet-0727a9b7f293de7f6","subnet-0571d20b4875c2279","subnet-01c923eff4afe4343"]

  tags = {
      Name = "adserverx_billing_rds_subnet_group1"
      Role = "adserverx billing rds subnet group"
  }
}

resource "aws_db_instance" "adserverx-billing-pg-rds" {
  identifier             = "adserverx-billing-pg-rds"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "13.1"
  username               = "postgresuser"
  #password              = var.db_password
  password               = random_password.adserverx_billing_pgrds_master_password.result
  db_subnet_group_name   = aws_db_subnet_group.adserverx_billing_rds_subnet_group.name
  vpc_security_group_ids = ["sg-0ed1b54fac7509a3a"]
  parameter_group_name   = aws_db_parameter_group.adserverx-billing-rds-parameter-group.name
  publicly_accessible    = true
  skip_final_snapshot    = true
  tags = {
      Name = "adserverx_billing_pg_rds1"
      Role = "adserverx billing pg rds1"
  }
}

resource "aws_db_parameter_group" "adserverx-billing-rds-parameter-group" {
  name   = "adserverx-billing-rds-parameter-group"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "random_password" "adserverx_billing_pgrds_master_password" {
  length  = 16
  special = false
}

data "aws_kms_key" "adserverx_kms_master_key_alias_data" {
  key_id = "alias/adserverx_kms_master_key_alias"
}

resource "aws_secretsmanager_secret" "adserverx_billing_pg_rds_secret" {
  name = "billing_pg_rds_secret"
  kms_key_id = data.aws_kms_key.adserverx_kms_master_key_alias_data.arn
  tags = {
      Name = "adserverx_billing_postgres_aws_secretsmanager_secret"
      Role = "adserverx billing postgres aws secretsmanager secret"
  }
}

resource "aws_secretsmanager_secret_version" "adserverx_billing_pgrds_credentials_secret_version" {
  secret_id     = aws_secretsmanager_secret.adserverx_billing_pg_rds_secret.id
  secret_string = <<EOF
{
  "username": "${aws_db_instance.adserverx-billing-pg-rds.username}",
  "password": "${random_password.adserverx_billing_pgrds_master_password.result}",
  "engine": "postgres",
  "host": "${aws_db_instance.adserverx-billing-pg-rds.endpoint}",
  "port": ${aws_db_instance.adserverx-billing-pg-rds.port},
  "dbClusterIdentifier": "${aws_db_instance.adserverx-billing-pg-rds.identifier}"
}
EOF
}

# resource "aws_secretsmanager_secret_rotation" "postgres_secret_rotation" {
#   rotation_lambda_arn = null
#   secret_id           = "${aws_secretsmanager_secret.adserverx_billing_pg_rds_secret.id}"
#   tags = {
#       Name = "adserverx_billing_postgres_secret_rotation_pg_rds1"
#       Role = "adserverx billing postgres secret rotation pg rds1"
#   }
#   rotation_rules {
#     automatically_after_days = null
#   }
# }