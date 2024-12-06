resource "random_pet" "this_database" {}

resource "aws_dynamodb_table" "this" {
  billing_mode = "PAY_PER_REQUEST"
  name         = random_pet.this_database.id
  hash_key     = "key"

  attribute {
    name = "key"
    type = "S"
  }
}

resource "aws_dynamodb_resource_policy" "this" {
  resource_arn = aws_dynamodb_table.this.arn
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Statement1",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.this.arn
        },
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
        "Resource" : [
          aws_dynamodb_table.this.arn
        ]
      }
    ]
  })
}