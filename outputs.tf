output "cloudfront_domain_name" {
  description = "Cloudfront domain name"
  value       = module.website.cloudfront_domain_name
}

output "rest_api" {
  description = "REST API information"
  value       = module.visitor_counter_backend.rest_api
  sensitive   = true
}