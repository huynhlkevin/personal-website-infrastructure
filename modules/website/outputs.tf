output "bucket_id" {
  description = "AWS bucket id"
  value       = aws_s3_bucket.bucket.id
}

output "cloudfront_domain_name" {
  description = "AWS CloudFront domain name"
  value       = aws_cloudfront_distribution.cloudfront.domain_name
}

output "certification_validation" {
  description = "Certification validation resource values"
  value = {
    "name"  = trimsuffix(one(aws_acm_certificate.cert.domain_validation_options).resource_record_name, ".")
    "value" = trimsuffix(one(aws_acm_certificate.cert.domain_validation_options).resource_record_value, ".")
  }
}