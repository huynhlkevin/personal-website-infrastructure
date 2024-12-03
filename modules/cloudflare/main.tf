terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_record" "cert_validation_record" {
  name    = var.certificate_validation.name
  type    = "CNAME"
  zone_id = var.cloudflare_zone_id
  content = var.certificate_validation.value
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