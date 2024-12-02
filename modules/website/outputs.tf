output "bucket_id" {
  description = "AWS bucket id"
  value       = aws_s3_bucket.bucket.id
}