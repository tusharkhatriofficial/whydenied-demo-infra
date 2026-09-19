terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# The app's config lives in Parameter Store.
resource "aws_ssm_parameter" "db_url" {
  name  = "/demo/orders-api/db-url"
  type  = "String"
  value = "postgres://orders.internal:5432/orders"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "orders_api" {
  name               = "orders-api-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Logs only. The role can NOT read the SSM parameter above; that's the bug
# WhyDenied is meant to catch and fix.
resource "aws_iam_role_policy_attachment" "orders_api_logs" {
  role       = aws_iam_role.orders_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "orders_api" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/build/orders-api.zip"
}

resource "aws_lambda_function" "orders_api" {
  function_name    = "orders-api"
  role             = aws_iam_role.orders_api.arn
  runtime          = "python3.14"
  architectures    = ["arm64"]
  handler          = "app.handler"
  filename         = data.archive_file.orders_api.output_path
  source_code_hash = data.archive_file.orders_api.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      DB_URL_PARAM = aws_ssm_parameter.db_url.name
    }
  }
}

output "function_name" {
  value = aws_lambda_function.orders_api.function_name
}
