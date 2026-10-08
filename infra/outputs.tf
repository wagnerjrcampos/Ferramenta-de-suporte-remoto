output "resource_group_name" {
  description = "Nome do Resource Group."
  value       = azurerm_resource_group.rg.name
}

output "automation_account_name" {
  description = "Nome da Automation Account."
  value       = azurerm_automation_account.aa.name
}

output "automation_account_id" {
  description = "ID da Automation Account."
  value       = azurerm_automation_account.aa.id
}

output "automation_account_principal_id" {
  description = "Principal ID da Managed Identity (System-assigned)."
  value       = azurerm_automation_account.aa.identity[0].principal_id
}

output "runbook_name" {
  description = "Nome do Runbook publicado."
  value       = azurerm_automation_runbook.runbook.name
}
