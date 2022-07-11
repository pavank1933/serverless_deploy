resource "aws_kms_key" "adserverx_kms_master_key" {
 description         = "adserverx_kms_master_key"
 enable_key_rotation = false

 tags = {
     Name = "adserverx_KMS_MASTER_KEY1"
     Role = "adserverx kms master key"
 }
 # policy = <<EOF
 # {
 #   "Version": "2012-10-17",
 #   "Statement": [
 #     {
 #       "Action": [
 #         "kms:*"
 #       ],
 #       "Principal": { "AWS": "*" },
 #       "Resource": "*"
 #     }
 #   ]
 # }
 # EOF
}

resource "aws_kms_alias" "adserverx_kms_master_key_alias" {
 name          = "alias/adserverx_kms_master_key_alias"
 target_key_id = aws_kms_key.adserverx_kms_master_key.key_id
}