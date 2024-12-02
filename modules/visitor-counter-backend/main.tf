resource "random_pet" "dynamodb_table" {}

resource "aws_dynamodb_table" "visitor" {
  billing_mode = "PAY_PER_REQUEST"
  name         = random_pet.dynamodb_table.id
  hash_key     = "key"

  attribute {
    name = "key"
    type = "S"
  }
}

resource "aws_dynamodb_resource_policy" "visitor" {
  resource_arn = aws_dynamodb_table.visitor.arn
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.visitor_lambda.arn
        },
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Resource" : [
          aws_dynamodb_table.visitor.arn
        ]
      }
    ]
  })
}

resource "random_pet" "rest_api" {}

resource "aws_api_gateway_rest_api" "visitor" {
  name = random_pet.rest_api.id
  body = data.template_file.visitor_rest_api.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "visitor" {
  rest_api_id = aws_api_gateway_rest_api.visitor.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.visitor.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_pet" "stage" {}

resource "aws_api_gateway_stage" "visitor" {
  rest_api_id   = aws_api_gateway_rest_api.visitor.id
  stage_name    = random_pet.stage.id
  deployment_id = aws_api_gateway_deployment.visitor.id
}

resource "aws_api_gateway_method_settings" "visitor" {
  rest_api_id = aws_api_gateway_rest_api.visitor.id
  stage_name  = aws_api_gateway_stage.visitor.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }
}

resource "random_pet" "api_key" {}

resource "aws_api_gateway_api_key" "visitor" {
  name = random_pet.api_key.id
}

resource "random_pet" "usage_plan" {}

resource "aws_api_gateway_usage_plan" "visitor" {
  name = random_pet.usage_plan.id

  api_stages {
    api_id = aws_api_gateway_rest_api.visitor.id
    stage  = aws_api_gateway_stage.visitor.stage_name
  }

  quota_settings {
    limit  = 450000
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 50
    rate_limit  = 100
  }
}

resource "aws_api_gateway_usage_plan_key" "visitor" {
  key_id        = aws_api_gateway_api_key.visitor.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.visitor.id
}

resource "aws_lambda_permission" "visitor_rest_api" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor.execution_arn}/*/POST/"
}

resource "aws_iam_role" "visitor_lambda" {
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "random_pet" "lambda_function" {}

resource "aws_lambda_function" "visitor" {
  function_name    = random_pet.lambda_function.id
  role             = aws_iam_role.visitor_lambda.arn
  filename         = data.archive_file.update_visitor_counter.output_path
  handler          = var.lambda_code.handler
  runtime          = "python3.13"
  source_code_hash = data.archive_file.update_visitor_counter.output_base64sha256

  environment {
    variables = {
      access_control_allow_origin = var.access_control_allow_origin
      visitor_table_name          = aws_dynamodb_table.visitor.id
    }
  }
}

data "template_file" "visitor_rest_api" {
  template = file(var.rest_api.path)

  vars = {
    lambda_arn                  = aws_lambda_function.visitor.arn
    access_control_allow_origin = var.access_control_allow_origin
  }
}

data "archive_file" "update_visitor_counter" {
  type        = "zip"
  source_file = var.lambda_code.path
  output_path = "lambda_function_payload.zip"
}