#Now I'm creating SNS to send an alert to my email
resource "aws_sns_topic" "GetParameterAbove1SNS" {
  name = "GetParameterAbove1SNS"
}

resource "aws_sns_topic_subscription" "GetParameterAbove1EmailSub" {
  topic_arn = aws_sns_topic.GetParameterAbove1SNS.arn
  protocol  = "email"
  endpoint  = "prosperademoye@gmail.com"
}


