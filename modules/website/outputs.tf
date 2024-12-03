output "bucket_id" {
  description = "AWS bucket id"
  value       = aws_s3_bucket.bucket.id
}

output "cloudfront_domain_name" {
  description = "AWS CloudFront domain name"
  value       = aws_cloudfront_distribution.cloudfront.domain_name
}