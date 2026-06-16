data "aws_caller_identity" "current" {}

data "aws_arn" "caller" {
  arn = data.aws_caller_identity.current.arn
}