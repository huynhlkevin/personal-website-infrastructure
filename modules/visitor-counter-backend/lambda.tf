data "archive_file" "this" {
  type        = "zip"
  source_file = var.lambda_code.path
  output_path = "lambda_function_payload.zip"
}

resource "random_pet" "this_lambda_function" {}

resource "aws_lambda_function" "this" {
  function_name    = random_pet.this_lambda_function.id
  role             = aws_iam_role.this.arn
  handler          = var.lambda_code.handler
  runtime          = "python3.13"

  environment {
    variables = {
      access_control_allow_origin = "https://${var.access_control_allow_origin}"
      visitor_table_name          = aws_dynamodb_table.this.id
    }
  }

  s3_bucket = aws_s3_bucket.this.id
  s3_key = aws_signer_signing_job.this.signed_object[0].s3[0].key
  code_signing_config_arn = aws_lambda_code_signing_config.this.arn
}

resource "aws_lambda_permission" "this" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/POST/"
}

resource "aws_iam_role" "this" {
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

resource "aws_lambda_code_signing_config" "this" {
  allowed_publishers {
    signing_profile_version_arns = [
      aws_signer_signing_profile.this.version_arn
    ]
  }

  policies {
    untrusted_artifact_on_deployment = "Enforce"
  }
}

resource "aws_signer_signing_profile" "this" {
  platform_id = "AWSLambda-SHA384-ECDSA"
}

resource "aws_signer_signing_job" "this" {
  profile_name = aws_signer_signing_profile.this.name

  source {
    s3 {
      bucket  = aws_s3_bucket.this.id
      key     = "unsigned/${data.archive_file.this.output_path}"
      version = aws_s3_object.this.version_id
    }
  }

  destination {
    s3 {
      bucket = aws_s3_bucket.this.id
      prefix = "signed/"
    }
  }
}

resource "random_pet" "this_bucket" {}

resource "aws_s3_bucket" "this" {
  bucket        = random_pet.this_bucket.id
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "this" {
    bucket = aws_s3_bucket.this.id
    key = "unsigned/${data.archive_file.this.output_path}"
    source = data.archive_file.this.output_path
}