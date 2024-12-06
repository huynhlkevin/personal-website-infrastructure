output "rest_api" {
  description = "REST API information"
  value = {
    invoke_url = aws_api_gateway_stage.this.invoke_url
    api_key    = aws_api_gateway_api_key.this.value
  }
}