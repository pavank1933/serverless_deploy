resource "aws_lambda_function" "adserverx_media-info_lambda" {
  function_name = "adserverx_media-info_lambda"
  #role         = "${aws_iam_role.adserverx_iam_lambda_role.arn}"
  role         = "${var.aws_iam_lambda_role_arn}" 
  package_type = "Image"
  image_uri =  format("%s.dkr.ecr.%s.amazonaws.com/%s:adserver-latest",var.aws_account_id,var.aws_region,var.ecr_repo)
  timeout      = 300
  vpc_config {
      subnet_ids         = var.aws_lambda_subnets
      security_group_ids = [var.aws_lambda_sg]
    }
  tags = {
      Name = "adserverx_media-info_lambda1"
      Role = "adserverx media-info lambda"
  }
  depends_on = [
    aws_iam_role_policy_attachment.adserverx_media-info_lambda_logs,
    aws_cloudwatch_log_group.adserverx_media-info_lambda_cloudwatch_log_group,
  ]
}

resource "aws_cloudwatch_log_group" "adserverx_media-info_lambda_cloudwatch_log_group" {
  name              = "/aws/lambda/adserverx_media-info_lambda"
  retention_in_days = 14
}

resource "aws_iam_role" "adserverx_media-info_iam_lambda_role" {
    name                 = "adserverx_media-info_iam_lambda_role"
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
      Name = "adserverx_media-info_iam_lambda_role1"
      Role = "adserverx media-info iam lambda role"
  }
}

resource "aws_iam_policy" "adserverx_media-info_lambda_logging" {
  name        = "adserverx_media-info_lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "adserverx_media-info_lambda_logs" {
  role       = aws_iam_role.adserverx_media-info_iam_lambda_role.name
  policy_arn = aws_iam_policy.adserverx_media-info_lambda_logging.arn
}

# resource "aws_lambda_permission" "adserverx_media-info_allow_cloudwatch" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = "${aws_lambda_function.adserverx_media-info_lambda.function_name}"
#   principal     = "events.amazonaws.com"
#   source_arn    = "${aws_cloudwatch_log_group.adserverx_media-info_lambda_cloudwatch_log_group.arn}:*"
#   qualifier     = aws_lambda_alias.adserverx_media-info_lambda_alias.name
# }

resource "aws_lambda_alias" "adserverx_media-info_lambda_alias" {
  name             = "adserverx_media-info_lambda_alias"
  description      = "adserverx_media-info_lambda_alias"
  function_name    ="${aws_lambda_function.adserverx_media-info_lambda.function_name}"
  function_version = "$LATEST"
}

resource "aws_apigatewayv2_api" "adserverx_media-info_apigw_api" {
  name          = "adserverx_media-info_apigw_api"
  protocol_type = "HTTP"
  
  tags = {
      Name = "adserverx_media-info_apigw_api1"
      Role = "adserverx media-info apigw api"
  }
}
  resource "aws_apigatewayv2_stage" "adserverx_media-info_apigw_stage" {
    api_id = aws_apigatewayv2_api.adserverx_media-info_apigw_api.id
  
    name        = "$default"
    auto_deploy = true

    # route_settings {
    #   route_key = "adserverx_media-info_lambda"
    # } 
    access_log_settings {
      destination_arn = aws_cloudwatch_log_group.adserverx_media-info_cloudwatch_log_group.arn
  
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
        Name = "adserverx_media-info_apigw_stage1"
        Role = "adserverx media-info apigw stage"
    }
  }

resource "aws_apigatewayv2_integration" "adserverx_media-info_apigw_integration" {
  api_id = aws_apigatewayv2_api.adserverx_media-info_apigw_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:adserverx_media-info_lambda/invocations"
}

resource "aws_apigatewayv2_route" "adserverx_media-info_apigw_route" {
  api_id = aws_apigatewayv2_api.adserverx_media-info_apigw_api.id
  route_key = "ANY /adserverx_media-info_lambda"
  #route_key = "$default"
  #route_key = "ANY /adserverx_media-info_apigw_stage"
  target    = "integrations/${aws_apigatewayv2_integration.adserverx_media-info_apigw_integration.id}"
}

resource "aws_cloudwatch_log_group" "adserverx_media-info_cloudwatch_log_group" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.adserverx_media-info_apigw_api.name}"

  retention_in_days = 30
  tags = {
      Name = "adserverx_media-info_cloudwatch_log_group1"
      Role = "adserverx media-info cloudwatch log group"
  }
}

resource "aws_lambda_permission" "adserverx_media-info_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.adserverx_media-info_lambda.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.adserverx_media-info_apigw_api.execution_arn}/*/*"
}