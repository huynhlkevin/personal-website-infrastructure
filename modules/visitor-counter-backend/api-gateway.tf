data "template_file" "this" {
  template = file(var.rest_api.path)

  vars = {
    lambda_arn                  = aws_lambda_function.this.arn
    access_control_allow_origin = "https://${var.access_control_allow_origin}"
  }
}

resource "random_pet" "this_api" {}

resource "aws_api_gateway_rest_api" "this" {
  name = random_pet.this_api.id
  body = data.template_file.this.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.this.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_pet" "this_stage" {}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = random_pet.this_stage.id
  deployment_id = aws_api_gateway_deployment.this.id
}

resource "aws_api_gateway_method_settings" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }
}

resource "random_pet" "this_api_key" {}

resource "aws_api_gateway_api_key" "this" {
  name = random_pet.this_api_key.id
}

resource "random_pet" "this_usage_plan" {}

resource "aws_api_gateway_usage_plan" "this" {
  name = random_pet.this_usage_plan.id

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.this.stage_name
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

resource "aws_api_gateway_usage_plan_key" "this" {
  key_id        = aws_api_gateway_api_key.this.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}