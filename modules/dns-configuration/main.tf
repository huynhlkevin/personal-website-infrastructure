terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_record" "cert_validation_record" {
  name    = trimsuffix(one(aws_acm_certificate.cert.domain_validation_options).resource_record_name, ".")
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  content = trimsuffix(one(aws_acm_certificate.cert.domain_validation_options).resource_record_value, ".")
}

resource "cloudflare_record" "record" {
  for_each = var.cnames
  name     = each.key
  type     = "CNAME"
  zone_id  = var.cloudflare_zone_id
  content  = each.value
  proxied  = true
}

resource "cloudflare_ruleset" "redirects" {
  kind    = "zone"
  name    = "Redirects"
  phase   = "http_request_dynamic_redirect"
  zone_id = var.cloudflare_zone_id

  rules {
    action      = "redirect"
    expression  = "(http.request.full_uri wildcard r\"https://${var.domain_name}/*\")"
    description = "Redirect from Root to WWW"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          expression = "wildcard_replace(http.request.full_uri, r\"https://${var.domain_name}/*\", r\"https://www.${var.domain_name}/$${1}\")"
        }
      }
    }
  }
}

resource "cloudflare_zone_dnssec" "dnssec" {
  zone_id = var.cloudflare_zone_id
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}