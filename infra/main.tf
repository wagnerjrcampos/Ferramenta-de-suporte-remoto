resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_automation_account" "aa" {
  name                = "${var.prefix}-aa"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

resource "azurerm_automation_runbook" "runbook" {
  name                    = "Invoke-RemoteSupportRunbook"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.aa.name
  runbook_type            = "PowerShell"
  log_progress            = true
  log_verbose             = false
  content                 = file("${path.module}/../runbooks/Invoke-RemoteSupportRunbook.ps1")

  tags = var.tags
}

# Alerta de budget de US$ 10/mês.
# Comentário obrigatório: exige permissões de subscription (Cost Management / Billing).
# Por isso fica atrás da variável enable_budget_alert (default false).
resource "azurerm_consumption_budget_resource_group" "budget" {
  count             = var.enable_budget_alert ? 1 : 0
  name              = "${var.prefix}-budget-10usd"
  resource_group_id = azurerm_resource_group.rg.id

  amount     = 10
  time_grain = "Monthly"

  time_period {
    start_date = "2026-10-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    contact_emails = [var.budget_alert_email]
  }
}
