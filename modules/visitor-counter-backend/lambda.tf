data "archive_file" "lambda" {
  type        = "zip"
  source_file = var.lambda_code.path
  output_path = "lambda_function_payload.zip"
}

resource "random_pet" "lambda" {}

resource "aws_lambda_function" "lambda" {
  function_name = random_pet.lambda.id
  role          = aws_iam_role.lambda.arn
  handler       = var.lambda_code.handler
  runtime       = "python3.13"

  environment {
    variables = {
      access_control_allow_origin = "https://${var.access_control_allow_origin}"
      visitor_table_name          = aws_dynamodb_table.database.id
    }
  }

  s3_bucket               = aws_s3_bucket.lambda.id
  s3_key                  = aws_signer_signing_job.lambda.signed_object[0].s3[0].key
  code_signing_config_arn = aws_lambda_code_signing_config.lambda.arn
}

resource "aws_lambda_permission" "lambda" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/POST/"
}

resource "aws_iam_role" "lambda" {
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

resource "aws_lambda_code_signing_config" "lambda" {
  allowed_publishers {
    signing_profile_version_arns = [
      aws_signer_signing_profile.lambda.version_arn
    ]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_signer_signing_profile" "lambda" {
  platform_id = "AWSLambda-SHA384-ECDSA"
}

resource "aws_signer_signing_job" "lambda" {
  profile_name = aws_signer_signing_profile.lambda.name

  source {
    s3 {
      bucket  = aws_s3_bucket.lambda.id
      key     = "unsigned/${data.archive_file.lambda.output_path}"
      version = aws_s3_object.lambda.version_id
    }
  }

  destination {
    s3 {
      bucket = aws_s3_bucket.lambda.id
      prefix = "signed/"
    }
  }
}

resource "random_pet" "lambda_bucket" {}

resource "aws_s3_bucket" "lambda" {
  bucket        = random_pet.lambda_bucket.id
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "lambda" {
  bucket = aws_s3_bucket.lambda.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "lambda" {
  bucket = aws_s3_bucket.lambda.id
  key    = "unsigned/${data.archive_file.lambda.output_path}"
  source = data.archive_file.lambda.output_path
}