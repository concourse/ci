output "instance_url" {
  value = "https://${hcloud_server.main.ipv4_address}.nip.io"
}

output "admin_password" {
  value     = random_string.admin_password.result
  sensitive = true
}

output "guest_password" {
  value     = random_string.guest_password.result
  sensitive = true
}
