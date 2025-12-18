output "log_bucket_name" {
  value = aws_s3_bucket.log_bucket.bucket
}

output "cloudtrail_name" {
  value = aws_cloudtrail.trail.name
}

output "cloudwatch_log_group" {
  value = aws_cloudwatch_log_group.logs.name
}