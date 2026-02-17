# NOTE: Azure Consumption Budgets require an Enterprise Agreement or MCA.
# If your subscription supports it, uncomment the block below.

# resource "azurerm_consumption_budget_resource_group" "openclaw_budget" {
#   name              = "openclaw-monthly-budget"
#   resource_group_id = azurerm_resource_group.rg.id
#   amount            = var.budget_amount
#   time_grain        = "Monthly"
#
#   time_period {
#     start_date = "${var.budget_start_date}T00:00:00Z"
#     end_date   = "${var.budget_end_date}T00:00:00Z"
#   }
#
#   notification {
#     enabled        = true
#     threshold      = 80.0
#     operator       = "EqualTo"
#     threshold_type = "Actual"
#
#     # In a real scenario, you'd add contact_emails here or an action group.
#     # For now, we just define the alert structure.
#     # contact_emails = ["user@example.com"] 
#     contact_roles = ["Owner", "Contributor"]
#   }
# }
