function Enable-RemoteWinRM {
    <#
    .SYNOPSIS
        Habilita o WinRM remotamente em uma máquina Entra ID joined.

    .DESCRIPTION
        Verifica conectividade de rede e o estado atual do WinRM na máquina alvo.
        Se o WinRM já estiver habilitado, não altera nada (idempotente). Caso
        contrário, executa a habilitação via CIM (Invoke-CimMethod em Win32_Process
        rodando Enable-PSRemoting/Enable-WinRM) e confirma o resultado com um
        novo teste WS-Management.

        Pensado para substituir o AnyDesk em chamados que travam
        no prompt de UAC ou reportam "não conectado", em ambiente Entra ID joined
        sem RMM (Intune/SCCM).

    .PARAMETER ComputerName
        Nome ou IP da(s) máquina(s) a configurar. Aceita múltiplos valores e pipeline.

    .PARAMETER Credential
        Credencial opcional para autenticar na máquina remota. Se omitida, usa o
        contexto da sessão atual.

    .EXAMPLE
        Enable-RemoteWinRM -ComputerName "NLESG002911"

        Habilita o WinRM em uma única máquina e retorna o status.

    .EXAMPLE
        "PC01", "PC02" | Enable-RemoteWinRM -Verbose

        Habilita o WinRM em múltiplas máquinas via pipeline, com log detalhado.

    .OUTPUTS
        [PSCustomObject] com ComputerName, Status, Detail e EnabledAt
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
                ComputerName = $Computer
                Status       = 'Unknown'
                Detail       = ''
                EnabledAt    = Get-Date
            }

            # Etapa 1 — falha rápida se a máquina nem responde à rede.
            Write-Verbose "[$Computer] Testando conectividade de rede..."
            $IsOnline = [bool](Test-Connection -ComputerName $Computer -Count 1 -Quiet -ErrorAction SilentlyContinue)

            if (-not $IsOnline) {
                $Result.Status = 'Offline'
                $Result.Detail = 'Máquina não respondeu ao ping. Verifique se está ligada/conectada antes de prosseguir.'
                Write-Verbose "[$Computer] Offline — habilitação ignorada."
                $Result
                continue
            }

            # Etapa 2 — se o WinRM já responde, não faz nada (idempotente).
            Write-Verbose "[$Computer] Online. Verificando estado atual do WinRM..."
            $AlreadyEnabled = $false
            try {
                $CheckParams = @{ ComputerName = $Computer; ErrorAction = 'Stop' }
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $CheckParams['Credential'] = $Credential
                }
                $null = Test-WSMan @CheckParams
                $AlreadyEnabled = $true
            }
            catch {
                Write-Verbose "[$Computer] WinRM ainda não ativo: $($_.Exception.Message)"
            }

            if ($AlreadyEnabled) {
                $Result.Status = 'AlreadyEnabled'
                $Result.Detail = 'WinRM já estava habilitado — nenhuma alteração feita.'
                Write-Verbose "[$Computer] WinRM já ativo — nada a fazer."
                $Result
                continue
            }

            # Etapa 3 — habilita o WinRM remotamente via CIM/Win32_Process.
            Write-Verbose "[$Computer] Habilitando WinRM via Invoke-CimMethod..."
            try {
                $EnableCommand = 'powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-PSRemoting -Force; Enable-WinRM -Force"'
                $CimParams = @{
                    ComputerName = $Computer
                    ClassName    = 'Win32_Process'
                    MethodName   = 'Create'
                    Arguments    = @{ CommandLine = $EnableCommand }
                    ErrorAction  = 'Stop'
                }
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $CimParams['Credential'] = $Credential
                }

                $CimResult = Invoke-CimMethod @CimParams

                if ($CimResult.ReturnValue -ne 0) {
                    throw "Win32_Process Create retornou código $($CimResult.ReturnValue)."
                }

                # Etapa 4 — confirma que o WinRM passou a responder.
                Write-Verbose "[$Computer] Aguardando e confirmando WinRM..."
                Start-Sleep -Seconds 5
                $VerifyParams = @{ ComputerName = $Computer; ErrorAction = 'Stop' }
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $VerifyParams['Credential'] = $Credential
                }
                $null = Test-WSMan @VerifyParams

                $Result.Status = 'Enabled'
                $Result.Detail = 'WinRM habilitado e confirmado com sucesso.'
                Write-Verbose "[$Computer] WinRM habilitado."
            }
            catch {
                $Result.Status = 'Failed'
                $Result.Detail = "Falha ao habilitar WinRM: $($_.Exception.Message)"
                Write-Verbose "[$Computer] Falha: $($_.Exception.Message)"
            }

            $Result
        }
    }
}
