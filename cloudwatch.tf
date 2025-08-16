#Create LogGroup to send the events to
resource "aws_cloudwatch_log_group" "PSLogGroup" {
  name = "Parameter-Store-Log-Group"
  retention_in_days = 90
}

#Create Role that Cloudtrail will assume, because it need a role to log into cloudwatch
data "aws_iam_policy_document" "cloudtrail_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

#IAM role that CloudTrail assumes to publish logs into CloudWatch Logs
resource "aws_iam_role" "cloudtrail_to_cw_logs" {
  name               = "CloudTrail_To_CloudWatch_Logs"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_assume_role.json
}

# Permissions that allow CloudTrail to create log streams and put log events into the CloudWatch Log Group
data "aws_iam_policy_document" "cloudtrail_logs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_group.PSLogGroup.arn}:*"
    ]
  }
}

#Join the policy with the role we created so cloudtrail can now be access cloudwath
resource "aws_iam_role_policy" "cloudtrail_logs_inline" {
  name   = "CloudTrailLogsWrite"
  role   = aws_iam_role.cloudtrail_to_cw_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_logs_policy.json
}


#Now I'm creating the metric filter in cloudwatch to help scan the log for specific patterns or words. In this case its for GetParameter
resource "aws_cloudwatch_log_metric_filter" "Parameter_store_Metric_Filter" {
  name           = "Parameter-Store-Metric_filter"
  pattern = "{ ($.eventSource = ssm.amazonaws.com) && ($.eventName = GetParameter) }"
  log_group_name = aws_cloudwatch_log_group.PSLogGroup.name

  metric_transformation {
    name      = "GetParameterCount"
    namespace = "GetParameterCountNamespace"
    value     = "1"
    default_value = "0"
  }
}

#Now I'm creating the alarm that will alert me when there is the filter metric goes above 1
resource "aws_cloudwatch_metric_alarm" "GetParameterAbove1Alarm" {
  alarm_name                = "GetParameterAbove1Alarm"
  statistic                 = "Sum"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  threshold                 = 1
  period                    = 60
  evaluation_periods        = 1
  metric_name               = "GetParameterCount"
  namespace = "GetParameterCountNamespace"
  
  
  alarm_description         = "This metric monitors when a parameter store key has been opened"
  insufficient_data_actions = []
  alarm_actions = [
    aws_sns_topic.GetParameterAbove1SNS.arn
  ]
}