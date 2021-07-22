output "base_domain" {
  value = local.base_domain
}

output "admin_password" {
  value     = random_password.admin_password.result
  sensitive = true
}
