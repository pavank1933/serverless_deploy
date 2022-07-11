# resource "aws_route53_zone" "adserverx_route53_zone" {
#   name = "adserverx.hosts"

#   tags = {
#       Name = "adserverx_route53_hostedzone"
#       Role = "adserverx route53 hostedzone"
#   }
# }

# resource "aws_route53_record" "adserverx_sqs_ns" {
#   zone_id = aws_route53_zone.adserverx_route53_zone.zone_id
#   name    = "s3file-sqs.adserverx.hosts"
#   type    = "NS"
#   ttl     = "300"
#   records = [
#     "${aws_sqs_queue.adserverx_sqs_queue.id}"
#   ] 
# }
 
# #Get Redis URL
# data "http" "adserverx_redis_primary_endpoint" {
#   #url = "${aws_elasticache_replication_group.adserverx_no_clustermode_with_replicas.configuration_endpoint_address}"
#   #url = aws_elasticache_replication_group.adserverx_no_clustermode_with_replicas.configuration_endpoint_address
#   #url = "https://adserverx-redis-rep-group-1.hfpsre.ng.0001.use1.cache.amazonaws.com"
#   #url = "http://${aws_elasticache_replication_group.adserverx_no_clustermode_with_replicas.configuration_endpoint_address}"
#   url = "adserverx-redis-rep-group-1.hfpsre.ng.0001.use1.cache.amazonaws.com"
# }

# resource "aws_route53_record" "adserverx_redis_ns" {
#   zone_id = aws_route53_zone.adserverx_route53_zone.zone_id
#   name    = "redis.adserverx.hosts"
#   type    = "NS"
#   ttl     = "300"
#   records = [
#     "${chomp(data.http.adserverx_redis_primary_endpoint.body)}"
#   ] 
# }