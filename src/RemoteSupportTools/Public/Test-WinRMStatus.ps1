function Test-WinRMStatus {
    <#
    .SYNOPSIS
        Verifica se o WinRM está habilitado e acessível em uma máquina remota.

    .DESCRIPTION
        Testa conectividade básica (ICMP) e, em seguida, uma conexão WS-Management (WinRM)
        via Test-WSMan. É uma checagem somente leitura — não altera nada na máquina alvo,
        portanto é seguro executar repetidamente (idempotente).

        Pensado para ambientes Entra ID joined sem GPO on-premises, onde a habilitação de
        WinRM precisa ser verificada individualmente por máquina antes de tentar PSRemoting
        como alternativa ao AnyDesk em chamados que travam no prompt de UAC.

    .PARAMETER ComputerName
        Nome ou IP da(s) máquina(s) a testar. Aceita múltiplos valores e pipeline.

    .PARAMETER Credential
        Credencial opcional para autenticar o teste WS-Management. Se omitida, usa o
        contexto da sessão atual (funciona quando já há permissão no tenant/domínio).

    .EXAMPLE
        Test-WinRMStatus -ComputerName "NLESG002911"

        Testa uma única máquina e retorna o status.

    .EXAMPLE
        "PC01", "PC02" | Test-WinRMStatus -Verbose

        Testa múltiplas máquinas via pipeline, com log detalhado de cada etapa.

    .OUTPUTS
        [PSCustomObject] com ComputerName, IsOnline, WinRMAvailable, Status, Detail, CheckedAt
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('CN', 'Name')]
        [string[]]$ComputerName,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        foreach ($Computer in $ComputerName) {

            if ([string]::IsNullOrWhiteSpace($Computer)) {
                throw 'ComputerName não pode ser vazio.'
            }

            $Result = [PSCustomObject]@{
                ComputerName   = $Computer
                IsOnline       = $false
                WinRMAvailable = $false
                Status         = 'Unknown'
                Detail         = ''
                CheckedAt      = Get-Date
            }

            # Etapa 1 — falha rápida se a máquina nem responde à rede.
            # Evita esperar timeout de WinRM numa máquina claramente offline.
            Write-Verbose "[$Computer] Testando conectividade de rede..."
            $Result.IsOnline = [bool](Test-Connection -ComputerName $Computer -Count 1 -Quiet -ErrorAction SilentlyContinue)

            if (-not $Result.IsOnline) {
                $Result.Status = 'Offline'
                $Result.Detail = 'Máquina não respondeu ao ping. Verifique se está ligada/conectada antes de prosseguir.'
                Write-Verbose "[$Computer] Offline — pulando teste de WinRM."
                $Result
                continue
            }

            # Etapa 2 — teste real de WS-Management (somente leitura, não altera configuração).
            Write-Verbose "[$Computer] Online. Testando WinRM..."
            try {
                $WSManParams = @{ ComputerName = $Computer; ErrorAction = 'Stop' }
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $WSManParams['Credential'] = $Credential
                }

                $null = Test-WSMan @WSManParams

                $Result.WinRMAvailable = $true
                $Result.Status = 'Available'
                $Result.Detail = 'WinRM respondeu normalmente. PSRemoting pode ser usado como alternativa ao AnyDesk.'
                Write-Verbose "[$Computer] WinRM disponível."
            }
            catch {
                $Result.Status = 'Unavailable'
                $Result.Detail = "WinRM não respondeu: $($_.Exception.Message)"
                Write-Verbose "[$Computer] WinRM indisponível: $($_.Exception.Message)"
            }

            $Result
        }
    }
}
