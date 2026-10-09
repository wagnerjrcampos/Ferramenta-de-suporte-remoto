variable "location" {
  description = "Região Azure para os recursos."
  type        = string
  default     = "brazilsouth"
}

variable "prefix" {
  description = "Prefixo usado no nome dos recursos."
  type        = string
  default     = "rstools"
}

variable "tags" {
  description = "Tags aplicadas a todos os recursos."
  type        = map(string)
  default = {
    env     = "homologacao"
    project = "ferramenta-de-suporte-remoto"
  }
}

variable "enable_budget_alert" {
  description = "Cria alerta de budget de US$ 10. ATENÇÃO: exige permissões de subscription para Cost Management."
  type        = bool
  default     = false
}

variable "budget_alert_email" {
  description = "E-mail que recebe o alerta de budget (usado apenas se enable_budget_alert = true)."
  type        = string
  default     = "finops@example.com"
}
