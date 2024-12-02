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

module "website" {
  source             = "./modules/website"
  domain_name        = var.DOMAIN_NAME
  cloudflare_zone_id = var.CLOUDFLARE_ZONE_ID
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
  bucket_id           = module.website.bucket_id
}