output "role_name" {
  description = "Role name that can be used in GitHub Actions when configurating AWS"
  value       = aws_iam_role.frontend_automation.name
}