variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "openclaw-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "centralindia"
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Username for the VM"
  type        = string
  default     = "clawadmin"
}

variable "allowed_ip_address" {
  description = "Public IP address allowed to SSH into the VM (CIDR format)"
  type        = string
}

variable "key_vault_name" {
  description = "Globally unique name for the Key Vault"
  type        = string
}



# variable "budget_amount" {
#   description = "Monthly budget amount in USD"
#   type        = number
#   default     = 30
# }

# variable "budget_start_date" {
#   description = "Start date for the budget (YYYY-MM-01)"
#   type        = string
#   default     = "2025-02-01"
# }

# variable "budget_end_date" {
#   description = "End date for the budget (YYYY-MM-DD)"
#   type        = string
#   default     = "2026-04-01"
# }

