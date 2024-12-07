output "role_name" {
  description = "AWS role name that can be used in GitHub Actions automation"
  value       = aws_iam_role.github.name
}