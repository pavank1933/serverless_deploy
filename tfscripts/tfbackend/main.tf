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
      Monitor       = "${var.tag_aws_env == "adserverx-prod" ? "YES" : "NO"}"
    }
  }
}

resource "aws_s3_bucket" "adserver-xterraform-state" {
  bucket = "adserverx-tfstate-qa"
  #bucket = "adserverx-tfstate-${var.artifact_version}"
  versioning {
    enabled = true
  }
  acl           = "private"
  force_destroy = true
  lifecycle_rule {
   enabled = true
   transition {
     days          = 30
     storage_class = "STANDARD_IA"
   }
   noncurrent_version_transition {
     days          = 30
     storage_class = "STANDARD_IA"
   }
 }
  tags = {
     Name = "adserverx-s3-tfstate1"
     Role = "adserverx s3 tfstate"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "app-state"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "LockID"
  
  tags = {
     Name = "adserverx-dynamodb-table1"
     Role = "adserverx dynamodb table"
  }
  attribute {
    name = "LockID"
    type = "S"
  }
}
