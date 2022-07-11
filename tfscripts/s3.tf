resource "aws_s3_bucket" "adserver-x" {
 bucket        = "adserverx-s3-${var.tag_aws_env}"
 acl           = "private"
 force_destroy = true
 server_side_encryption_configuration {
   rule {
     apply_server_side_encryption_by_default {
       kms_master_key_id = aws_kms_key.adserverx_kms_master_key.arn
       sse_algorithm     = "aws:kms"
     }
   }
 }

 versioning {
   enabled = true
 }

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
     Name = "adserverx_S3_Bucket1"
     Role = "adserverx S3 Bucket"
 }
}

resource "aws_s3_bucket_object" "adserverx-s3-bucket-phov" {
   bucket  = aws_s3_bucket.adserver-x.id
   acl     = "private"
   key     =  "phov/"
   kms_key_id = "${aws_kms_key.adserverx_kms_master_key.arn}"
}

resource "aws_s3_bucket_object" "adserverx-s3-bucket-ipexclusion" {
   bucket  = aws_s3_bucket.adserver-x.id
   acl     = "private"
   key     =  "ip-exclusion/"
   kms_key_id = "${aws_kms_key.adserverx_kms_master_key.arn}"
}