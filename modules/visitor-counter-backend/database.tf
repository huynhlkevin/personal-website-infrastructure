resource "random_pet" "database_table" {}

resource "aws_dynamodb_table" "database" {
  billing_mode = "PAY_PER_REQUEST"
  name         = random_pet.database_table.id
  hash_key     = "key"

  attribute {
    name = "key"
    type = "S"
  }
}

resource "aws_dynamodb_resource_policy" "database" {
  resource_arn = aws_dynamodb_table.database.arn
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.lambda.arn
        },
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Resource" : [
          aws_dynamodb_table.database.arn
        ]
      }
    ]
  })
}