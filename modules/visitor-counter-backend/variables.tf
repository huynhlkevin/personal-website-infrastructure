variable "lambda_code" {
  description = "Lambda code parameters"
  type = object({
    path    = string
    handler = string
  })
}

variable "rest_api" {
  description = "REST API code parameters"
  type = object({
    path = string
  })
}

variable "access_control_allow_origin" {
  description = "Allow resource access to this origin"
  type        = string
}