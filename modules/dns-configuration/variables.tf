variable "cloudflare_zone_id" {
  description = "Domain zone id"
  type        = string
}

variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "cnames" {
  description = "CNAME mappings"
  type        = map(string)
}