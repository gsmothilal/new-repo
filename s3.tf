########################################
# Random Suffix (to avoid name conflicts)
########################################

resource "random_id" "suffix" {
  byte_length = 4
}

########################################
# S3 Log Archive Bucket (COBL-006 Item 2)
########################################

resource "aws_s3_bucket" "log_bucket" {
  bucket = var.log_bucket_name

  tags = {
    Purpose = "COBL-006-Logging"
    Owner   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.log_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "retention" {
  bucket = aws_s3_bucket.log_bucket.id

  rule {
    id     = "log-retention"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = 2555 # ~7 years
    }
  }
}

########################################
# CloudTrail Bucket Policy (COBL-006 Item 1)
########################################

data "aws_iam_policy_document" "cloudtrail_policy" {
  statement {
    sid = "AWSCloudTrailWrite"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.log_bucket.arn}/AWSLogs/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSCloudTrailAclCheck"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.log_bucket.arn]
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.log_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_policy.json
}

########################################
# CloudTrail (COBL-006 Item 1)
########################################

resource "aws_cloudtrail" "trail" {
  name = "cobl-006-cloudtrail-${random_id.suffix.hex}"

  s3_bucket_name                = aws_s3_bucket.log_bucket.bucket
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_logging                = true
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

########################################
# CloudWatch Log Group (COBL-006 Item 1)
########################################

resource "aws_cloudwatch_log_group" "logs" {
  name = "/cobl-006/application-logs-${random_id.suffix.hex}"

  retention_in_days = var.cloudwatch_retention_days
}
