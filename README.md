📜 CloudTrail + CloudWatch + SNS Monitoring (Terraform)

This Terraform configuration sets up an alerting pipeline to detect when AWS Systems Manager (SSM) Parameter Store parameters are accessed via the GetParameter API.

The system uses:

CloudTrail to capture API calls

CloudWatch Logs & Metric Filters to detect specific events

CloudWatch Alarms to trigger on suspicious activity

SNS to notify you via email

🗂 Project Structure
.
├─ providers.tf   # AWS provider, region, and identity data
├─ cloudtrail.tf  # CloudTrail setup + S3 bucket + IAM role/policies
├─ cloudwatch.tf  # Log group, metric filter, and alarm definition
├─ sns.tf         # SNS topic and email subscription

⚙️ What This Does

CloudTrail

Creates an S3 bucket for CloudTrail logs.

Configures CloudTrail to capture API activity.

Sends logs to a CloudWatch Log Group.

CloudWatch

Creates a log group for CloudTrail events.

Sets up a metric filter that looks for SSM GetParameter events:

{ ($.eventSource = "ssm.amazonaws.com") && ($.eventName = "GetParameter") }


Creates an alarm that triggers if ≥ 1 GetParameter event occurs in a 1-minute window.

SNS

Creates an SNS topic.

Subscribes your email to receive alerts.

📦 Prerequisites

Terraform v1.5+

AWS CLI configured with credentials

A globally unique S3 bucket name for CloudTrail logs

A valid email address for SNS subscription

🚀 Deployment

Set variables (either in variables.tf or via CLI). For example:

variable "cloudtrail_bucket_name" {
  default = "your-unique-cloudtrail-bucket"
}

variable "sns_email" {
  default = "your-email@example.com"
}


Initialize and apply:

terraform init
terraform apply


Confirm your SNS subscription from the email AWS sends you.
(Until you confirm, alarms won’t deliver notifications.)

🧪 Testing

Run a simple SSM Parameter Store call:

aws ssm get-parameter --name <your-parameter-name>


Go to CloudWatch → Metrics → GetParameterCountNamespace → GetParameterCount
You should see the metric increment.

Within ~1 minute, the alarm will enter ALARM state and send you an email.

📤 Outputs

After a successful terraform apply, you’ll see:

cloudtrail_bucket_name – S3 bucket name storing CloudTrail logs

cloudwatch_log_group – Log group receiving CloudTrail events

sns_topic_arn – SNS topic ARN for notifications

🧹 Cleanup

To destroy all resources:

terraform destroy

🔒 Notes & Next Steps

Log group retention defaults to 90 days (can be adjusted).

This setup is a baseline pattern — you can add more metric filters, e.g.:

Unauthorized API calls: { $.errorCode = "AccessDenied*" }

Console logins: { $.eventName = "ConsoleLogin" }

Root user usage: { $.userIdentity.type = "Root" }

SNS can be extended to trigger Slack, PagerDuty, or Lambda.

✅ With this setup you now have an auditable, automated way to detect and alert on sensitive SSM Parameter Store usage.