data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}
provider "aws" {
  region = "us-east-1"
}
