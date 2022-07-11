variable "aws_account_id" {
  description = "AWS Account ID"
}

variable "aws_region" {
  description = "AWS Region"
}

variable "ecr_repo" {
  description = "AWS ECR Repo"
}

variable "aws_iam_lambda_role_arn" {
    description = "AWS iam lambda role"
}

# variable "artifact_version" {
#     description = "Latest version of artifact"
# }

variable "aws_iam_lambda_role_name" {
    description = "AWS iam lambda role"
}

variable "aws_lambda_sg" {
    description = "AWS lambda SG"
}

variable "aws_lambda_subnets" {
    description = "AWS lambda subnets"
}