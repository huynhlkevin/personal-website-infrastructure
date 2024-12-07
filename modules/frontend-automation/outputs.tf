output "role_arn" {
  description = "AWS role arn that can be used in GitHub Actions automation"
  value       = aws_iam_role.github.arn
}