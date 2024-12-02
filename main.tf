terraform {
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = "~> 1.10"

  cloud {
    organization = "huynhlkevin"

    workspaces {
      name = "personal-website-infrastructure"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

provider "aws" {
  alias  = "east"
  region = "us-east-1"
}

provider "cloudflare" {

}

resource "aws_s3_bucket" "bucket" {
  bucket = var.DOMAIN_NAME
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
  aliases             = ["*.${var.DOMAIN_NAME}"]
  default_root_object = "index.html"
  enabled             = false

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
  domain_name       = "*.${var.DOMAIN_NAME}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "dns_validation" {
  name    = trimsuffix(one(aws_acm_certificate.cert.domain_validation_options).resource_record_name, ".")
  type    = "CNAME"
  zone_id = var.CLOUDFLARE_ZONE_ID
  content = trimsuffix(one(aws_acm_certificate.cert.domain_validation_options).resource_record_value, ".")
}

resource "cloudflare_record" "root" {
  name    = "@"
  type    = "CNAME"
  zone_id = var.CLOUDFLARE_ZONE_ID
  content = aws_cloudfront_distribution.cloudfront.domain_name
  proxied = true
}

resource "cloudflare_record" "www" {
  name    = "www"
  type    = "CNAME"
  zone_id = var.CLOUDFLARE_ZONE_ID
  content = aws_cloudfront_distribution.cloudfront.domain_name
  proxied = true
}

resource "cloudflare_ruleset" "redirects" {
  kind    = "zone"
  name    = "Redirects"
  phase   = "http_request_dynamic_redirect"
  zone_id = var.CLOUDFLARE_ZONE_ID

  rules {
    action      = "redirect"
    expression  = "(http.request.full_uri wildcard r\"https://${var.DOMAIN_NAME}/*\")"
    description = "Redirect from Root to WWW"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          expression = "wildcard_replace(http.request.full_uri, r\"https://${var.DOMAIN_NAME}/*\", r\"https://www.${var.DOMAIN_NAME}/$${1}\")"
        }
      }
    }
  }
}

resource "cloudflare_zone_dnssec" "dnssec" {
  zone_id = var.CLOUDFLARE_ZONE_ID
}

module "visitor_counter_backend" {
  source                      = "./modules/visitor-counter-backend"
  access_control_allow_origin = "https://www.${var.DOMAIN_NAME}"

  lambda_code = {
    path    = "./resources/lambda/update_visitor_counter.py"
    handler = "update_visitor_counter.lambda_handler"
  }

  rest_api = {
    path = "./resources/apigateway/oas30.json.tpl"
  }
}

module "frontend_automation" {
  source              = "./modules/frontend-automation"
  role_name           = "FrontendAutomation"
  github_organization = "huynhlkevin"
  github_repository   = "personal-website"
  bucket_id           = aws_s3_bucket.bucket.id
}