provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket" {
  bucket        = var.domain_name
  force_destroy = true
}

resource "aws_s3_bucket_policy" "cloudfront_oac_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Id" : "PolicyForCloudFrontPrivateContent",
    "Statement" : [
      {
        "Sid" : "AllowCloudFrontServicePrincipal",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "cloudfront.amazonaws.com"
        },
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*",
        "Condition" : {
          "StringEquals" : {
            "AWS:SourceArn" : aws_cloudfront_distribution.cloudfront.arn
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "cloudfront" {
  aliases             = ["*.${var.domain_name}"]
  default_root_object = "index.html"
  enabled             = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    target_origin_id       = aws_s3_bucket.bucket.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
  }

  origin {
    domain_name              = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = aws_s3_bucket.bucket.bucket_regional_domain_name
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = aws_s3_bucket.bucket.bucket_regional_domain_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.east
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}