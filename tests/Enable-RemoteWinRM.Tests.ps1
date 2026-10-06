BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\src\RemoteSupportTools\RemoteSupportTools.psd1'
    Import-Module $ModulePath -Force
}

Describe 'Enable-RemoteWinRM' {

    Context 'Validação de entrada' {
        It 'Rejeita ComputerName vazio' {
            { Enable-RemoteWinRM -ComputerName '' } | Should -Throw
        }

        It 'Exige o parâmetro ComputerName' {
            (Get-Command Enable-RemoteWinRM).Parameters['ComputerName'].Attributes.Mandatory | Should -Contain $true
        }
    }

    Context 'Máquina offline' {
        BeforeAll {
            Mock Test-Connection { $false } -ModuleName RemoteSupportTools
            Mock Test-WSMan {} -ModuleName RemoteSupportTools
            Mock Invoke-CimMethod {} -ModuleName RemoteSupportTools
        }

        It 'Retorna Status Offline e não tenta habilitar' {
            $result = Enable-RemoteWinRM -ComputerName 'PC-OFFLINE'

            $result.Status | Should -Be 'Offline'
            Should -Invoke Invoke-CimMethod -Times 0 -ModuleName RemoteSupportTools
            Should -Invoke Test-WSMan -Times 0 -ModuleName RemoteSupportTools
        }
    }

    Context 'WinRM já habilitado (idempotente)' {
        BeforeAll {
            Mock Test-Connection { $true } -ModuleName RemoteSupportTools
            Mock Test-WSMan { [PSCustomObject]@{ ProductVersion = 'OS: 0.0.0 SP: 0.0 Stack: 3.0' } } -ModuleName RemoteSupportTools
            Mock Invoke-CimMethod {} -ModuleName RemoteSupportTools
        }

        It 'Retorna Status AlreadyEnabled e não altera nada' {
            $result = Enable-RemoteWinRM -ComputerName 'PC-JA-OK'

            $result.Status | Should -Be 'AlreadyEnabled'
            Should -Invoke Invoke-CimMethod -Times 0 -ModuleName RemoteSupportTools
        }
    }

    Context 'WinRM desabilitado, habilitação com sucesso' {
        BeforeAll {
            Mock Test-Connection { $true } -ModuleName RemoteSupportTools
            $global:WsManCalls = 0
            Mock Test-WSMan {
                $global:WsManCalls++
                if ($global:WsManCalls -eq 1) { throw 'WinRM não responde' }
                [PSCustomObject]@{}
            } -ModuleName RemoteSupportTools
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0 } } -ModuleName RemoteSupportTools
            Mock Start-Sleep {} -ModuleName RemoteSupportTools
        }

        It 'Habilita via CIM e confirma o resultado' {
            $result = Enable-RemoteWinRM -ComputerName 'PC-SEM-WINRM'

            $result.Status | Should -Be 'Enabled'
            Should -Invoke Invoke-CimMethod -Times 1 -ModuleName RemoteSupportTools
            Should -Invoke Test-WSMan -Times 2 -ModuleName RemoteSupportTools
        }
    }

    Context 'Verificação falha após habilitar' {
        BeforeAll {
            Mock Test-Connection { $true } -ModuleName RemoteSupportTools
            Mock Test-WSMan { throw 'WinRM não responde' } -ModuleName RemoteSupportTools
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 0 } } -ModuleName RemoteSupportTools
            Mock Start-Sleep {} -ModuleName RemoteSupportTools
        }

        It 'Retorna Status Failed após esgotar as tentativas' {
            $result = Enable-RemoteWinRM -ComputerName 'PC-VERIF-FALHA'

            $result.Status | Should -Be 'Failed'
            $result.Detail | Should -Match 'tentativas'
            Should -Invoke Test-WSMan -Times 6 -ModuleName RemoteSupportTools
        }
    }

    Context 'Falha na habilitação' {
        BeforeAll {
            Mock Test-Connection { $true } -ModuleName RemoteSupportTools
            Mock Test-WSMan { throw 'WinRM não responde' } -ModuleName RemoteSupportTools
            Mock Invoke-CimMethod { [PSCustomObject]@{ ReturnValue = 2 } } -ModuleName RemoteSupportTools
        }

        It 'Retorna Status Failed com detalhe do erro' {
            $result = Enable-RemoteWinRM -ComputerName 'PC-FALHA'

            $result.Status | Should -Be 'Failed'
            $result.Detail | Should -Match 'Win32_Process'
        }
    }

    Context 'Múltiplas máquinas via pipeline' {
        BeforeAll {
            Mock Test-Connection { $true } -ModuleName RemoteSupportTools
            Mock Test-WSMan { [PSCustomObject]@{} } -ModuleName RemoteSupportTools
        }

        It 'Retorna um resultado por máquina' {
            $results = 'PC1', 'PC2', 'PC3' | Enable-RemoteWinRM
            $results.Count | Should -Be 3
        }
    }
}
