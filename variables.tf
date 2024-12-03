variable "CLOUDFLARE_ZONE_ID" {
  description = "Cloudflare domain zone id. Value is set in Terraform cloud as a workspace environmental variable."
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "huynhlkevin.com"
}