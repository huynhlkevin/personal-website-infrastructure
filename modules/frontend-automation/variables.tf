variable "github_organization" {
  description = "GitHub organization name allowed to assume the role"
  type        = string
}

variable "github_repository" {
  description = "GitHub organization repository allowed to assume the role"
  type        = string
}

variable "bucket_id" {
  description = "AWS S3 bucket destination of the frontend content"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution of the frontend content"
  type        = string
}