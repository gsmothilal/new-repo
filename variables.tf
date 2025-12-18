variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "log_bucket_name" {
  description = "Central S3 bucket for logs"
  type        = string
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch log retention days"
  type        = number
  default     = 90
}