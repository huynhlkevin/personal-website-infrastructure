data "template_file" "visitor_rest_api" {
  template = file("resources/apigateway/oas30.json.tpl")

  vars = {
    api_version                 = "1.0.0"
    lambda_arn                  = "arn:aws:lambda:us-west-1:864899855377:function:addVisitor"
    access_control_allow_origin = "https://www.${var.DOMAIN_NAME}"
  }
}