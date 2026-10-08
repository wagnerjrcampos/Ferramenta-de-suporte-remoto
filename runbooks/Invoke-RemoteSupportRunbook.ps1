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
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ComputerName,

    [Parameter(Mandatory)]
    [ValidateSet('Test', 'Enable')]
    [string]$Acao
)

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
