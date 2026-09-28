## Título

Função PowerShell: checar e habilitar WinRM remotamente via Entra ID/Graph

## Contexto
Chamados de suporte remoto via AnyDesk frequentemente travam quando aparece o
prompt de UAC (tela preta) ou o AnyDesk reporta "não conectado". Hoje a única
saída é pedir a senha de admin ao usuário — prática insegura — ou perder tempo
tentando contornar manualmente. Não há RMM (Intune/SCCM) no ambiente.

## Objetivo
Ter uma função PowerShell reutilizável que verifica remotamente se o WinRM
está habilitado numa máquina Entra ID joined e, se necessário, habilita —
permitindo assumir a sessão via PSRemoting como alternativa ao AnyDesk nesses
casos específicos.

## Critérios de aceite
- [ ] Função `Test-WinRMStatus` retorna se WinRM está habilitado/acessível na máquina alvo
- [ ] Função `Enable-RemoteWinRM` habilita WinRM remotamente (via método compatível com Entra ID joined, sem AD on-premises)
- [ ] Ambas validam entrada (nome/IP da máquina) e tratam erros (máquina offline, sem permissão, timeout)
- [ ] Log de execução (o que foi feito, sucesso/falha) para rastreabilidade
- [ ] Testado em pelo menos 1 máquina de laboratório antes de qualquer uso real
- [ ] README explica pré-requisitos, uso e riscos

## Fora de escopo (por enquanto)
- Empacotamento como Azure Automation Runbook/Function (fica para Fase 2)
- Integração automática com GLPI
- Qualquer execução em máquina de usuário em produção sem teste prévio

## Riscos
- Habilitar WinRM remotamente pode mexer em firewall/rede da máquina — só testar em lab primeiro
- Requer permissões administrativas — documentar exatamente qual escopo é necessário

## Tarefas
- [ ] Levantar método de habilitação remota compatível com Entra ID joined (sem GPO on-prem)
- [ ] Implementar `Test-WinRMStatus`
- [ ] Implementar `Enable-RemoteWinRM`
- [ ] Criar testes com Pester
- [ ] Configurar pipeline GitHub Actions (lint + test a cada push)
- [ ] Documentar no README
- [ ] Validar em máquina de laboratório

## Labels sugeridas
`powershell` `automação` `infra` `p0`
