data "template_file" "api" {
  template = file(var.rest_api.path)

  vars = {
    lambda_arn                  = aws_lambda_function.lambda.arn
    access_control_allow_origin = "https://${var.access_control_allow_origin}"
  }
}

resource "random_pet" "api_gateway" {}

resource "aws_api_gateway_rest_api" "api" {
  name = random_pet.api_gateway.id
  body = data.template_file.api.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_pet" "api_stage" {}

resource "aws_api_gateway_stage" "api" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = random_pet.api_stage.id
  deployment_id = aws_api_gateway_deployment.api.id
}

resource "aws_api_gateway_method_settings" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }
}

resource "random_pet" "api_key" {}

resource "aws_api_gateway_api_key" "api" {
  name = random_pet.api_key.id
}

resource "random_pet" "usage_plan" {}

resource "aws_api_gateway_usage_plan" "api" {
  name = random_pet.usage_plan.id

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.api.stage_name
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

resource "aws_api_gateway_usage_plan_key" "api" {
  key_id        = aws_api_gateway_api_key.api.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.api.id
}