output "cloudfront_domain_name" {
  description = "Cloudfront domain name"
  value       = module.website.cloudfront_domain_name
}

output "rest_api_invoke_url" {
  description = "REST API invoke url"
  value       = module.visitor_counter_backend.rest_api.invoke_url
}

output "rest_api_key" {
  description = "REST API key"
  value       = module.visitor_counter_backend.rest_api.api_key
  sensitive   = true
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = module.website.bucket_id
}

output "frontend_automation_aws_role" {
  description = "AWS role arn that can be used in GitHub Actions automation"
  value       = module.frontend_automation.role_arn
}