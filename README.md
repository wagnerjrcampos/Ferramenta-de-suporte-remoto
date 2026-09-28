# Ferramenta de Suporte Remoto

Módulo PowerShell para diagnosticar e habilitar acesso remoto (WinRM/PSRemoting)
em máquinas Entra ID joined, como alternativa a chamados de AnyDesk que travam
no prompt de UAC ou reportam "não conectado".

## Status
🚧 Em desenvolvimento — ver [Issues](../../issues) para o roadmap.

## Por que existe
Ambiente sem RMM (Intune/SCCM). Hoje a única saída em falhas de AnyDesk é
pedir senha de admin ao usuário — prática insegura que este projeto elimina.

## Uso
_(documentar após primeira versão funcional)_

## Requisitos
- PowerShell 5.1+
- Permissões administrativas na máquina alvo
- Microsoft Graph PowerShell SDK
