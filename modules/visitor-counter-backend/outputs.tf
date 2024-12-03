output "rest_api" {
  description = "REST API information"
  value = {
    invocation_url = aws_api_gateway_stage.visitor.invoke_url
    api_key        = aws_api_gateway_api_key.visitor.value
  }
}