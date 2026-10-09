<#
.SYNOPSIS
    Ponto de entrada do Runbook de suporte remoto (Azure Automation).

.DESCRIPTION
    Importa o módulo RemoteSupportTools (de src/) e executa a ação solicitada
    contra o computador informado. Sem interatividade: pensado para execução
    serverless em Azure Automation / Hybrid Runbook Worker.

.PARAMETER ComputerName
    Nome ou IP da máquina alvo.

.PARAMETER Acao
    Ação a executar: 'Test' chama Test-WinRMStatus; 'Enable' chama Enable-RemoteWinRM.

.EXAMPLE
    .\Invoke-RemoteSupportRunbook.ps1 -ComputerName "NLESG002911" -Acao Test
#>
[CmdletBinding()]
param(
    # Sem Mandatory: contexto serverless (Azure Automation) nao pode exibir prompt interativo.
    # Fallback: variavel de ambiente RUNBOOK_COMPUTERNAME; se ausente, falha rapido com erro claro.
    [Parameter()]
    [string]$ComputerName = $env:RUNBOOK_COMPUTERNAME,

    # Sem Mandatory: default seguro 'Test' (somente leitura) para nunca pedir input.
    [Parameter()]
    [ValidateSet('Test', 'Enable')]
    [string]$Acao = 'Test'
)

if ([string]::IsNullOrWhiteSpace($ComputerName)) {
    throw "ComputerName nao informado. Passe -ComputerName ou defina a variavel de ambiente RUNBOOK_COMPUTERNAME."
}

$ModulePath = Join-Path $PSScriptRoot '..\src\RemoteSupportTools\RemoteSupportTools.psd1'
Import-Module $ModulePath -Force

switch ($Acao) {
    'Test' {
        $Result = Test-WinRMStatus -ComputerName $ComputerName
    }
    'Enable' {
        $Result = Enable-RemoteWinRM -ComputerName $ComputerName
    }
}

# Imprime o objeto de resultado (log do job no Azure Automation).
$Result
