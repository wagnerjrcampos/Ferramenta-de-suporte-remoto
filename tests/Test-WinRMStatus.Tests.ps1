BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot '..\src\RemoteSupportTools\RemoteSupportTools.psd1'
    Import-Module $ModulePath -Force
}

Describe 'Test-WinRMStatus' {

    Context 'Validação de entrada' {
        It 'Rejeita ComputerName vazio' {
            { Test-WinRMStatus -ComputerName '' } | Should -Throw
        }

        It 'Exige o parâmetro ComputerName' {
            (Get-Command Test-WinRMStatus).Parameters['ComputerName'].Attributes.Mandatory | Should -Contain $true
        }
    }

    Context 'Máquina offline' {
        BeforeAll {
            Mock Test-Connection { $false } -ModuleName RemoteSupportTools
            Mock Test-WSMan {} -ModuleName RemoteSupportTools
        }

        It 'Retorna Status Offline e não tenta WinRM' {
            $result = Test-WinRMStatus -ComputerName 'PC-OFFLINE'

            $result.IsOnline | Should -BeFalse
            $result.WinRMAvailable | Should -BeFalse
            $result.Status | Should -Be 'Offline'
            Should -Invoke Test-WSMan -Times 0 -ModuleName RemoteSupportTools
        }
    }

    Context 'Máquina online com WinRM disponível' {
        BeforeAll {
            Mock Test-Connection { $true } -ModuleName RemoteSupportTools
            Mock Test-WSMan { [PSCustomObject]@{ ProductVersion = 'OS: 0.0.0 SP: 0.0 Stack: 3.0' } } -ModuleName RemoteSupportTools
        }

        It 'Retorna Status Available' {
            $result = Test-WinRMStatus -ComputerName 'PC-ONLINE'

            $result.IsOnline | Should -BeTrue
            $result.WinRMAvailable | Should -BeTrue
            $result.Status | Should -Be 'Available'
        }
    }

    Context 'Máquina online mas WinRM indisponível' {
        BeforeAll {
            Mock Test-Connection { $true } -ModuleName RemoteSupportTools
            Mock Test-WSMan { throw 'WinRM cannot complete the operation.' } -ModuleName RemoteSupportTools
        }

        It 'Retorna Status Unavailable com detalhe do erro' {
            $result = Test-WinRMStatus -ComputerName 'PC-NO-WINRM'

            $result.WinRMAvailable | Should -BeFalse
            $result.Status | Should -Be 'Unavailable'
            $result.Detail | Should -Match 'WinRM'
        }
    }

    Context 'Múltiplas máquinas via pipeline' {
        BeforeAll {
            Mock Test-Connection { $true } -ModuleName RemoteSupportTools
            Mock Test-WSMan { [PSCustomObject]@{} } -ModuleName RemoteSupportTools
        }

        It 'Retorna um resultado por máquina' {
            $results = 'PC1', 'PC2', 'PC3' | Test-WinRMStatus
            $results.Count | Should -Be 3
        }
    }
}
