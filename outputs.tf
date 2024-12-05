output "cloudfront_domain_name" {
  description = "Cloudfront domain name"
  value       = module.website.cloudfront_domain_name
  sensitive   = true
}

output "rest_api_invoke_url" {
  description = "REST API invoke url"
  value       = module.visitor_counter_backend.rest_api.invoke_url
  sensitive   = true
}

output "rest_api_key" {
  description = "REST API key"
  value       = module.visitor_counter_backend.rest_api.api_key
  sensitive   = true
}

output "bucket_name" {
  description = "S3 bucket name"
  value       = module.website.bucket_id
  sensitive   = true
}