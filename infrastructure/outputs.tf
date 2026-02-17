output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

output "ssh_command" {
  value = "ssh -i openclaw_key.pem ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

output "private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "identity_client_id" {
  value = azurerm_user_assigned_identity.vm_identity.client_id
}

output "upload_secrets_commands" {
  value = <<EOT
# Run these commands to populate your Key Vault:
az keyvault secret set --vault-name ${azurerm_key_vault.kv.name} --name tailscale-auth-key --value "YOUR_TAILSCALE_KEY"
EOT
}
