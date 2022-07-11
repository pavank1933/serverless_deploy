resource "aws_lambda_function" "adserverx_ads_lambda" {
  function_name = "adserverx_ads_lambda"
  role         = "${var.aws_iam_lambda_role_arn}" 
  package_type = "Image"
  image_uri =  format("%s.dkr.ecr.%s.amazonaws.com/%s:adserver-latest",var.aws_account_id,var.aws_region,var.ecr_repo)
  timeout      = 300

  vpc_config {
      subnet_ids         = var.aws_lambda_subnets
      security_group_ids = [var.aws_lambda_sg]
    }

  tags = {
      Name = "adserverx_ads_lambda1"
      Role = "adserverx ads lambda"
  }
  depends_on = [
    aws_iam_role_policy_attachment.adserverx_ads_lambda_logs,
    #aws_cloudwatch_log_group.adserverx_new_ads_lambda_cloudwatch_log_group,
    aws_cloudwatch_log_group.adserverx_rest_ads_cloudwatch_log_group,
  ]
}

# resource "aws_cloudwatch_log_group" "adserverx_new_ads_lambda_cloudwatch_log_group" {
#   name              = "/aws/lambda/adserverx_new_ads_lambda"
#   retention_in_days = 14
# }

resource "aws_iam_role" "adserverx_ads_iam_lambda_role" {
    name                 = "adserverx_ads_iam_lambda_role"
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
      Name = "adserverx_ads_iam_lambda_role1"
      Role = "adserverx ads iam lambda role"
  }
}

resource "aws_iam_policy" "adserverx_ads_lambda_logging" {
  name        = "adserverx_ads_lambda_logging"
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

resource "aws_iam_role_policy_attachment" "adserverx_ads_lambda_logs" {
  role       = aws_iam_role.adserverx_ads_iam_lambda_role.name
  policy_arn = aws_iam_policy.adserverx_ads_lambda_logging.arn
}

# resource "aws_lambda_permission" "adserverx_ads_allow_cloudwatch" {
#   statement_id  = "AllowExecutionFromCloudWatch"
#   action        = "lambda:InvokeFunction"
#   function_name = "${aws_lambda_function.adserverx_ads_lambda.function_name}"
#   principal     = "events.amazonaws.com"
#   source_arn    = "${aws_cloudwatch_log_group.adserverx_new_ads_lambda_cloudwatch_log_group.arn}:*"
#   qualifier     = aws_lambda_alias.adserverx_ads_lambda_alias.name
# }

resource "aws_lambda_alias" "adserverx_ads_lambda_alias" {
  name             = "adserverx_ads_lambda_alias"
  description      = "adserverx_ads_lambda_alias"
  function_name    ="${aws_lambda_function.adserverx_ads_lambda.function_name}"
  function_version = "$LATEST"
}





# #################################ADS V2 GATEWAY API#############################################################
# resource "aws_apigatewayv2_api" "adserverx_ads_apigw_api" {
#   name          = "adserverx_ads_apigw_api"
#   protocol_type = "HTTP"
#   tags = {
#       Name = "adserverx_ads_apigw_api1"
#       Role = "adserverx ads apigw api"
#   }
# }

#   resource "aws_apigatewayv2_stage" "adserverx_ads_apigw_stage" {
#     api_id = aws_apigatewayv2_api.adserverx_ads_apigw_api.id
  
#     name        = "$default"
#     auto_deploy = true
#     #deployment_id = aws_apigatewayv2_deployment.adserverx_ads_apigw_deployment.id


#     # route_settings {
#     #   route_key = "adserverx_ads_lambda"
#     # }

#     access_log_settings {
#       destination_arn = aws_cloudwatch_log_group.adserverx_ads_cloudwatch_log_group.arn
  
#       format = jsonencode({
#         requestId               = "$context.requestId"
#         sourceIp                = "$context.identity.sourceIp"
#         requestTime             = "$context.requestTime"
#         protocol                = "$context.protocol"
#         httpMethod              = "$context.httpMethod"
#         resourcePath            = "$context.resourcePath"
#         routeKey                = "$context.routeKey"
#         status                  = "$context.status"
#         responseLength          = "$context.responseLength"
#         integrationErrorMessage = "$context.integrationErrorMessage"
#         }
#       )
#     }
#     tags = {
#         Name = "adserverx_ads_apigw_stage2"
#         Role = "adserverx ads apigw stage"
#     }
#   }

# resource "aws_apigatewayv2_integration" "adserverx_ads_apigw_integration" {
#   api_id = aws_apigatewayv2_api.adserverx_ads_apigw_api.id
#   integration_type   = "AWS_PROXY"
#   integration_method = "POST"
#   integration_uri    = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.aws_region}:${var.aws_account_id}:function:adserverx_ads_lambda/invocations"
# }

# resource "aws_apigatewayv2_route" "adserverx_ads_apigw_route" {
#   api_id = aws_apigatewayv2_api.adserverx_ads_apigw_api.id
#   route_key = "ANY /adserverx_ads_lambda"
#   #route_key = "ANY /adserverx_ads_apigw_stage"
#   #route_key = "$default"
#   target    = "integrations/${aws_apigatewayv2_integration.adserverx_ads_apigw_integration.id}"
# }

# resource "aws_cloudwatch_log_group" "adserverx_ads_cloudwatch_log_group" {
#   name = "/aws/api_gw/${aws_apigatewayv2_api.adserverx_ads_apigw_api.name}"

#   retention_in_days = 30
#   tags = {
#       Name = "adserverxads_cloudwatch_log_group1"
#       Role = "adserverx ads cloudwatch log group"
#   }
# }

# resource "aws_lambda_permission" "adserverx_ads_permission" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = "${aws_lambda_function.adserverx_ads_lambda.function_name}"
#   principal     = "apigateway.amazonaws.com"
#   source_arn = "${aws_apigatewayv2_api.adserverx_ads_apigw_api.execution_arn}/*/*"
# }






#################################ADS REST GATEWAY API#############################################################
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
  uri                     = aws_lambda_function.adserverx_ads_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "adserverx_ads_rest_api_gateway_deployment" {
   depends_on = [
     aws_api_gateway_integration.adserverx_ads_rest_api_gateway_proxy_integration
   ]

   rest_api_id = aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.id
   stage_name  = "staging"
}


########################### NEW CODE ###########################
resource "aws_cloudwatch_log_group" "adserverx_rest_ads_cloudwatch_log_group" {
  name = "/aws/api_gw/${aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.name}"

  retention_in_days = 30
  tags = {
      Name = "adserverx_ads_rest_cloudwatch_log_group1"
      Role = "adserverx ads rest cloudwatch log group"
  }
}

# resource "aws_api_gateway_stage" "adserverx_rest_ads_staging" {
#   deployment_id = aws_api_gateway_deployment.adserverx_ads_rest_api_gateway_deployment.id
#   rest_api_id   = aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.id
#   stage_name    = "staging"
# }
########################### NEW CODE ###########################



resource "aws_lambda_permission" "adserverx_ads_rest_api_gateway_lambda_permission" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.adserverx_ads_lambda.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.adserverx_ads_rest_api_gateway.execution_arn}/*/*"
}