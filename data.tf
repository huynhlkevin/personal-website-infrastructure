data "template_file" "visitor_rest_api" {
  template = file("resources/apigateway/oas30.json.tpl")

  vars = {
    api_version                 = "1.0.0"
    lambda_arn                  = aws_lambda_function.visitor.arn
    access_control_allow_origin = "https://www.${var.DOMAIN_NAME}"
  }
}

data "archive_file" "update_visitor_counter" {
  type        = "zip"
  source_file = "resources/lambda/update_visitor_counter.py"
  output_path = "lambda_function_payload.zip"
}