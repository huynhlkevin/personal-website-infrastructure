output "bucket_id" {
  description = "AWS bucket id"
  value       = aws_s3_bucket.bucket.id
}

output "cloudfront_domain_name" {
  description = "AWS CloudFront domain name"
  value       = aws_cloudfront_distribution.cloudfront.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.cloudfront.id
}