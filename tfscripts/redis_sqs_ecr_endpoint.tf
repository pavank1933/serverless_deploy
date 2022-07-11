# resource "aws_elasticache_cluster" "adserverx_redis" {
#  cluster_id           = "adserverx-redis"
#  engine               = "redis"
#  node_type            = "cache.r6g.large"
#  num_cache_nodes      = 1
#  #parameter_group_name = "default.redis6.x"
#  #engine_version       = "6.0.5"
#  port                 = 6379
#  subnet_group_name    = "${aws_elasticache_subnet_group.adserverx-redis-subnet-group.name}"
#  security_group_ids = ["${aws_security_group.adserverx_vpc_security_group1.id}"]
#  #security_group_names = ["${aws_security_group.adserverx_vpc_security_group1.name}"]
#  #security_group_names = ["${aws_elasticache_security_group.adserverx-redis_sg-terraform-test-01.name}"]
#  availability_zone = "us-east-1a"
#  #depends_on = [aws_elasticache_subnet_group.adserverx-redis-subnet-group]
#  tags = {
#      Name = "adserverx_redis1"
#      Role = "adserverx redis1"
#  }
# }

#Example: https://github.com/william-hou-ca/terraform_aws_elasticache/blob/088063e37444e9769267a18de5c1b1ea6a2a4772/main.tf#L15
resource "aws_elasticache_replication_group" "adserverx_no_clustermode_with_replicas" {
 # apply changes immediatly to cluster
 apply_immediately  = true
 automatic_failover_enabled    = true
 engine = "redis"

 # Redis settings
 replication_group_id          = "adserverx-redis-rep-group-1"
 replication_group_description = "redis cluster mode disabled and with replicas"
 #engine_version       = "6.x"
 port                          = 6379
 #parameter_group_name          = "default.redis6.x"
 node_type                     = "cache.r6g.large"
 number_cache_clusters         = 2 #  The number of cache clusters (primary and replicas) this replication group will have
 multi_az_enabled = true

 # Advanced Redis settings
 subnet_group_name           = "${aws_elasticache_subnet_group.adserverx-redis-subnet-group.name}"
 #availability_zones            = ["us-east-1a"]
 availability_zones            = ["us-east-1a", "us-east-1b"]

 # Security
 security_group_ids = ["${aws_security_group.adserverx_vpc_security_group1.id}"]
 at_rest_encryption_enabled = true
 kms_key_id = "${aws_kms_key.adserverx_kms_master_key.arn}"
 # transit_encryption_enabled = true
 # auth_token = 

 # Import data to cluster
 # snapshot_arns = ""
 # snapshot_name = ""

 # Backup
 #snapshot_retention_limit = 0
 #snapshot_window  = "05:00-09:00"

 # Maintenance
 #maintenance_window = "sun:01:00-sun:03:00"
 # notification_topic_arn = ""

 lifecycle {
   ignore_changes = [number_cache_clusters]
 }
 tags = {
     Name = "adserverx_redis1"
     Role = "adserverx redis1"
 }
}

output "adserverx_rep_group_endpoint" {
  value       = aws_elasticache_replication_group.adserverx_no_clustermode_with_replicas.configuration_endpoint_address
  description = "adserverx rep group endpoint"
}

# cluster atteched to replication group
resource "aws_elasticache_cluster" "adserverx_replica" {
 cluster_id           = "adserverx-redis-replica"
 replication_group_id = aws_elasticache_replication_group.adserverx_no_clustermode_with_replicas.id
}

resource "aws_elasticache_subnet_group" "adserverx-redis-subnet-group" {
 #depends_on = [aws_subnet.adserverx_private_subnet]
 name       = "adserverx-redis-subnet-group"
 subnet_ids = ["${aws_subnet.adserverx_private_subnet[0].id}", "${aws_subnet.adserverx_private_subnet[1].id}"]
 
 #subnet_ids = ["${module.vpc.private_subnet_ids[0]}","${module.vpc.private_subnet_ids[1]}"]
 #subnet_ids = ["${module.vpc.adserverx_private_subnets_output[*]}"]
 #subnet_ids = ["${module.vpc.adserverx_private_first_subnet_output}","${module.vpc.adserverx_private_second_subnet_output}"]
 tags = {
     Name = "adserverx_redis_subnet_group1"
     Role = "adserverx redis subnet group1"
 }
}

resource "aws_sqs_queue" "adserverx_sqs_queue" {
 name                  = "adserverx_sqs_queue.fifo"
 visibility_timeout_seconds = "14400"
 fifo_queue            = true
 kms_master_key_id     = "alias/adserverx_kms_master_key_alias"
 content_based_deduplication = true
 deduplication_scope   = "queue"
 fifo_throughput_limit = "perQueue"
 tags = {
     Name = "adserverx_sqs_queue1"
     Role = "adserverx sqs queue"
 }
}

output "adserverx_sqs_queue_endpoint" {
  value       = aws_sqs_queue.adserverx_sqs_queue.id
  description = "The endpoint of the adserverx_sqs_queue_endpoint"
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn = aws_sqs_queue.adserverx_sqs_queue.arn
  #function_name    = "${aws_lambda_function.adserverx_processSQSS3FileEvent_lambda.arn}"
  #function_name    = "${module.adserverx_apigw.aws_lambda_function.adserverx_processSQSS3FileEvent_lambda.arn}"
  #function_name    = "${data.aws_lambda_function.adserverx_data_lambda.name}"
  function_name    = "${module.adserverx_apigw.adserverx_processSQSS3FileEvent_lambda_name}"
}

# resource "aws_ecr_repository" "adserverx_ecr_repo" {
#  name = "adserverx_ecr_repo1"
#  tags = {
#      Name = "adserverx_ecr_repo1"
#      Role = "adserverx ecr repo"
#  }
# }

resource "aws_vpc_endpoint" "adserverx_s3_vpc_endpoint" {
  vpc_id       = "${aws_vpc.adserverx_vpc.id}"
  #vpc_id = "${module.vpc.vpc_id}"
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = ["${aws_route_table.adserverx_public_route.id}","${aws_route_table.adserverx_private_route_table.id}"]
  #route_table_ids = ["${module.vpc.adserverx_public_route_table}","${module.vpc.adserverx_private_route_table}"]
  
    policy = <<POLICY
    {
    "Statement": [
        {
        "Action": "*",
        "Effect": "Allow",
        "Resource": "*",
        "Principal": "*"
        }
    ]
    }
    POLICY
    tags = {
       Name = "adserverx_s3_vpc_endpoint1"
       Role = "adserverx s3 vpc endpoint"
    }
}

#
resource "aws_vpc_endpoint" "adserverx_sqs_vpc_endpoint" {
 vpc_id              = "${aws_vpc.adserverx_vpc.id}"
 #vpc_id              = "${module.vpc.vpc_id}"
 service_name        = "com.amazonaws.us-east-1.sqs"
 vpc_endpoint_type   = "Interface"
 security_group_ids  = ["${aws_security_group.adserverx_vpc_security_group1.id}"]
 #subnet_ids = ["${module.vpc.adserverx_private_subnets_output[*]}"]
 #subnet_ids = ["${module.vpc.private_subnet_ids[0]}","${module.vpc.private_subnet_ids[1]}"]
 #subnet_ids = ["${module.vpc.adserverx_private_first_subnet_output}"]
 subnet_ids          = ["${aws_subnet.adserverx_private_subnet[0].id}"]
 private_dns_enabled = true
 tags = {
     Name = "adserverx_sqs_vpc_endpoint1"
     Role = "adserverx sqs endpoint"
 }
}

resource "aws_vpc_endpoint" "adserverx_lambda_vpc_endpoint" {
 vpc_id              = "${aws_vpc.adserverx_vpc.id}"
 #vpc_id              = "${module.vpc.vpc_id}"
 service_name        = "com.amazonaws.us-east-1.lambda"
 vpc_endpoint_type   = "Interface"
 security_group_ids  = ["${aws_security_group.adserverx_vpc_security_group1.id}"]
 #subnet_ids = ["${module.vpc.adserverx_private_subnets_output[*]}"]
 #subnet_ids = ["${module.vpc.private_subnet_ids[0]}","${module.vpc.private_subnet_ids[1]}"]
 #subnet_ids = ["${module.vpc.adserverx_private_first_subnet_output}"]
 subnet_ids          = ["${aws_subnet.adserverx_private_subnet[0].id}"]
 private_dns_enabled = true   #Change this later in other environments
 tags = {
     Name = "adserverx_lambda_vpc_endpoint1"
     Role = "adserverx lambda vpc endpoint"
 }
}

resource "aws_vpc_endpoint" "adserverx_apigw_vpc_endpoint" {
 #vpc_id              = "${module.vpc.vpc_id}"
 vpc_id              = "${aws_vpc.adserverx_vpc.id}"
 service_name        = "com.amazonaws.us-east-1.execute-api"
 vpc_endpoint_type   = "Interface"
 security_group_ids  = [aws_security_group.adserverx_vpc_security_group1.id]
 #subnet_ids = ["${module.vpc.adserverx_private_subnets_output[*]}"]
 #subnet_ids = ["${module.vpc.private_subnet_ids[0]}","${module.vpc.private_subnet_ids[1]}"]
 #subnet_ids = ["${module.vpc.adserverx_private_first_subnet_output}"]
 subnet_ids          = ["${aws_subnet.adserverx_private_subnet[0].id}"]
 private_dns_enabled = true
 tags = {
     Name = "adserverx_apigw_vpc_endpoint1"
     Role = "adserverx apigw vpc endpoint"
 }
}
