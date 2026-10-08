BeforeAll {
    $ScriptPath = Join-Path $PSScriptRoot '..\runbooks\Invoke-RemoteSupportRunbook.ps1'
}

Describe 'Invoke-RemoteSupportRunbook' {

    Context 'Arquivo e sintaxe' {
        It 'Arquivo existe' {
            Test-Path $ScriptPath | Should -BeTrue
        }

        It 'Parseia sem erro' {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
    }

    Context 'Parâmetros' {
        BeforeAll {
            $Cmd = Get-Command $ScriptPath
        }

        It 'Expõe o parâmetro ComputerName' {
            $Cmd.Parameters.ContainsKey('ComputerName') | Should -BeTrue
            $Cmd.Parameters['ComputerName'].Attributes.Mandatory | Should -Contain $true
        }

        It 'Expõe o parâmetro Acao' {
            $Cmd.Parameters.ContainsKey('Acao') | Should -BeTrue
            $Cmd.Parameters['Acao'].Attributes.Mandatory | Should -Contain $true
        }

        It "Acao aceita apenas 'Test' e 'Enable'" {
            $ValidateSet = $Cmd.Parameters['Acao'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $ValidateSet | Should -Not -BeNullOrEmpty
            $ValidateSet.ValidValues | Should -Contain 'Test'
            $ValidateSet.ValidValues | Should -Contain 'Enable'
            $ValidateSet.ValidValues.Count | Should -Be 2
        }
    }
}
