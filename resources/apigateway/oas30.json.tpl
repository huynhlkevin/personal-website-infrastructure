{
  "openapi" : "3.0.1",
  "info" : {
    "title" : "",
    "version" : "${api_version}"
  },
  "paths" : {
    "/" : {
      "post" : {
        "responses" : {
          "200" : {
            "description" : "200 response",
            "content" : {
              "application/json" : {
                "schema" : {
                  "$ref" : "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "security" : [ {
          "api_key" : [ ]
        } ],
        "x-amazon-apigateway-integration" : {
          "type" : "aws_proxy",
          "httpMethod" : "POST",
          "uri" : "arn:aws:apigateway:us-west-1:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "responses" : {
            "default" : {
              "statusCode" : "200"
            }
          },
          "passthroughBehavior" : "when_no_match",
          "timeoutInMillis" : 29000,
          "contentHandling" : "CONVERT_TO_TEXT"
        }
      },
      "options" : {
        "responses" : {
          "200" : {
            "description" : "200 response",
            "headers" : {
              "Access-Control-Allow-Origin" : {
                "schema" : {
                  "type" : "string"
                }
              },
              "Access-Control-Allow-Methods" : {
                "schema" : {
                  "type" : "string"
                }
              },
              "Access-Control-Allow-Headers" : {
                "schema" : {
                  "type" : "string"
                }
              }
            },
            "content" : {
              "application/json" : {
                "schema" : {
                  "$ref" : "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "x-amazon-apigateway-integration" : {
          "type" : "mock",
          "responses" : {
            "default" : {
              "statusCode" : "200",
              "responseParameters" : {
                "method.response.header.Access-Control-Allow-Methods" : "'POST'",
                "method.response.header.Access-Control-Allow-Headers" : "'X-Api-Key'",
                "method.response.header.Access-Control-Allow-Origin" : "'${access_control_allow_origin}'"
              }
            }
          },
          "requestTemplates" : {
            "application/json" : "{\"statusCode\": 200}"
          },
          "passthroughBehavior" : "when_no_templates"
        }
      }
    }
  },
  "components" : {
    "schemas" : {
      "Empty" : {
        "title" : "Empty Schema",
        "type" : "object"
      }
    },
    "securitySchemes" : {
      "api_key" : {
        "type" : "apiKey",
        "name" : "x-api-key",
        "in" : "header"
      }
    }
  }
}