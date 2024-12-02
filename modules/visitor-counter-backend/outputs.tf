output "invoke_url" {
  description = "REST API invoke url"
  value       = aws_api_gateway_stage.visitor.invoke_url
}