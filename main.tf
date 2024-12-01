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
    "Version" = "2008-10-17",
    "Id"      = "PolicyForCloudFrontPrivateContent",
    "Statement" = [
      {
        "Sid"    = "AllowCloudFrontServicePrincipal",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "cloudfront.amazonaws.com"
        },
        "Action"   = "s3:GetObject",
        "Resource" = "arn:aws:s3:::${aws_s3_bucket.bucket.id}/*",
        "Condition" = {
          "StringEquals" = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cloudfront.arn
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

resource "aws_dynamodb_table" "visitor" {
  billing_mode = "PAY_PER_REQUEST"
  name         = "visitor"
  hash_key     = "key"

  attribute {
    name = "key"
    type = "S"
  }
}

resource "aws_dynamodb_resource_policy" "visitor" {
  resource_arn = aws_dynamodb_table.visitor.arn
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Sid"    = "Statement1",
        "Effect" = "Allow",
        "Principal" = {
          "AWS" = aws_iam_role.visitor_lambda.arn
        },
        "Action" = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Resource" = [
          aws_dynamodb_table.visitor.arn
        ]
      }
    ]
  })
}

resource "aws_api_gateway_rest_api" "visitor" {
  name = "My REST API"
  body = data.template_file.visitor_rest_api.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "visitor" {
  rest_api_id = aws_api_gateway_rest_api.visitor.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.visitor.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "visitor" {
  rest_api_id   = aws_api_gateway_rest_api.visitor.id
  stage_name    = "visit"
  deployment_id = aws_api_gateway_deployment.visitor.id
}

resource "aws_api_gateway_method_settings" "visitor" {
  rest_api_id = aws_api_gateway_rest_api.visitor.id
  stage_name  = aws_api_gateway_stage.visitor.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 50
    throttling_rate_limit  = 100
  }
}

resource "aws_api_gateway_api_key" "visitor" {
  name = "Visitor"
}

resource "aws_api_gateway_usage_plan" "visitor" {
  name = "Visitor"

  api_stages {
    api_id = aws_api_gateway_rest_api.visitor.id
    stage  = aws_api_gateway_stage.visitor.stage_name
  }

  quota_settings {
    limit  = 450000
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = 50
    rate_limit  = 100
  }
}

resource "aws_api_gateway_usage_plan_key" "visitor" {
  key_id        = aws_api_gateway_api_key.visitor.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.visitor.id
}

resource "aws_lambda_permission" "visitor_rest_api" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor.execution_arn}/*/POST/"
}

resource "aws_iam_role" "visitor_lambda" {
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_lambda_function" "visitor" {
  function_name = "updateVisitorCounter"
  role          = aws_iam_role.visitor_lambda.arn
  filename      = "lambda_function_payload.zip"
  handler       = "update_visitor_counter.lambda_handler"
  runtime       = "python3.13"
}