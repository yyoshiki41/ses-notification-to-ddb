
provider "aws" {
  region  = "eu-central-1"
  version = "~> 3.55.0"
}

locals {
  aws_account_id = "123123123" # your aws account id
  aws_region     = "eu-central-1" # the aws region where you deploy the infrastructure
}

###################################################################
## SES notification to ddb
# rif: https://github.com/yyoshiki41/ses-notification-to-ddb
#      https://aws.amazon.com/it/premiumsupport/knowledge-center/lambda-sns-ses-dynamodb/?nc1=h_ls
#sns receive from ses
resource "aws_sns_topic" "ses-to-ddb" {
  name = "ses-notification-to-ddb"
}


# allow ses to write on the sns topic, every ses's arn on our account is allowed
# rif: https://docs.aws.amazon.com/ses/latest/DeveloperGuide/configure-sns-notifications.html#configure-feedback-notifications-prerequisites
resource "aws_sns_topic_policy" "ses-to-ddb" {
  arn = aws_sns_topic.ses-to-ddb.arn

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "notification-policy",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ses.amazonaws.com"
      },
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.ses-to-ddb.arn}",
      "Condition": {
        "StringEquals": {
          "AWS:SourceAccount": "${local.aws_account_id}"
        },
        "StringLike": {
          "AWS:SourceArn": "arn:aws:ses:${local.aws_region}:${local.aws_account_id}:identity/*"
        }
      }
    }
  ]
}
POLICY
}

# subsctibe the lambda to the sns
# rif: https://github.com/spring-media/terraform-aws-lambda/blob/v5.2.1/examples/example-with-sns-event/main.tf
resource "aws_sns_topic_subscription" "lambda-to-sns" {
  topic_arn = aws_sns_topic.ses-to-ddb.arn
  protocol  = "lambda"
  endpoint  = module.ses-notification-to-ddb.lambda_function_arn
}

# deploy the lambda with terraform-aws-modules/lambda/aws module
module "ses-notification-to-ddb" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "2.11.0"

  lambda_at_edge = false

  function_name = "ses-notification-to-ddb"
  description   = "ses to sns to dynamodb"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"

  source_path = ".."

  attach_cloudwatch_logs_policy = true

  #rif: https://github.com/terraform-aws-modules/terraform-aws-lambda/blob/master/examples/complete/main.tf
  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["DynamoDB:PutItem"],
      resources = [aws_dynamodb_table.sesnotifications.arn]
    }
  }

  #rif: https://github.com/yyoshiki41/ses-notification-to-ddb/blob/master/template.yaml
  timeout = 10

  environment_variables = {
    TABLE_SES_NOTIFICATIONS = aws_dynamodb_table.sesnotifications.id
  }

  # rif: https://github.com/terraform-aws-modules/terraform-aws-lambda/blob/master/examples/triggers/main.tf
  allowed_triggers = {
    SnsSesNotifications = {
      principal  = "sns.amazonaws.com"
      source_arn = aws_sns_topic.ses-to-ddb.arn
    }
  }

  publish = true

  attach_policy = true
  policy        = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}


# https://github.com/yyoshiki41/ses-notification-to-ddb/blob/master/dynamodb_table.json
# dynamo table
resource "aws_dynamodb_table" "sesnotifications" {
  name         = "SESNotifications"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SESMessageId"


  attribute {
    name = "SESMessageId"
    type = "S"
  }

  attribute {
    name = "SnsPublishTime"
    type = "S"
  }

  attribute {
    name = "SESSenderAddress"
    type = "S"
  }

  global_secondary_index {
    name               = "GSI_SESSenderAddress_SnsPublishTime"
    hash_key           = "SESSenderAddress"
    range_key          = "SnsPublishTime"
    projection_type    = "INCLUDE"
    non_key_attributes = ["SESMessageId", "SESMessageType", "SESDestinationAddress"]
  }


  point_in_time_recovery {
    enabled = false
  }

  #encrypt with the default key
  server_side_encryption {
    enabled = true
  }

}
