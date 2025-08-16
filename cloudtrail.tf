#Create S3 Bucket
resource "aws_s3_bucket" "cloudtrail_s3_bucket" {
  bucket        = "cloudtrail-s3-bucket-lalallapoplopo"
  force_destroy = true
}

#Create Policy for CLoudtrail to access S3
data "aws_iam_policy_document" "trail_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_s3_bucket.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/Parameter-Store-Trail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_s3_bucket.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/Parameter-Store-Trail"]
    }
  }
}

#Attach the created policy to S3
resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_s3_bucket.id
  policy = data.aws_iam_policy_document.trail_bucket_policy.json
}

#Create Cloudtrail
resource "aws_cloudtrail" "ParameterStoreMytrail" {
  depends_on = [aws_s3_bucket_policy.trail_bucket_policy]

  name                          = "Parameter-Store-Trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_s3_bucket.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.PSLogGroup.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cw_logs.arn
}






