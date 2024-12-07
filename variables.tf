variable "CLOUDFLARE_ZONE_ID" {
  description = "Cloudflare domain zone id"
  type        = string
  default     = ""
}

variable "DOMAIN_NAME" {
  description = "Domain name"
  type        = string
  default     = ""
}

variable "frontend_automation_role_name" {
  description = "Name used for frontend automation role"
  type        = string
  default     = "FrontendAutomation"
}