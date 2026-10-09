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

        It 'ComputerName existe e NAO é Mandatory (sem prompt interativo)' {
            $Cmd.Parameters.ContainsKey('ComputerName') | Should -BeTrue
            $ParamAttr = $Cmd.Parameters['ComputerName'].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $ParamAttr.Mandatory | Should -BeFalse
        }

        It 'Acao existe e NAO é Mandatory (sem prompt interativo)' {
            $Cmd.Parameters.ContainsKey('Acao') | Should -BeTrue
            $ParamAttr = $Cmd.Parameters['Acao'].Attributes | Where-Object { $_ -is [System.Management.Automation.ParameterAttribute] }
            $ParamAttr.Mandatory | Should -BeFalse
        }

        It "Acao aceita apenas 'Test' e 'Enable'" {
            $ValidateSet = $Cmd.Parameters['Acao'].Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }
            $ValidateSet | Should -Not -BeNullOrEmpty
            $ValidateSet.ValidValues | Should -Contain 'Test'
            $ValidateSet.ValidValues | Should -Contain 'Enable'
            $ValidateSet.ValidValues.Count | Should -Be 2
        }

        It "Acao tem default 'Test'" {
            $errors = $null; $tokens = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
            $AcaoParam = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'Acao' }
            $AcaoParam.DefaultValue.SafeGetValue() | Should -Be 'Test'
        }

        It 'ComputerName tem fallback via variavel de ambiente' {
            $errors = $null; $tokens = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$tokens, [ref]$errors)
            $CnParam = $ast.ParamBlock.Parameters | Where-Object { $_.Name.VariablePath.UserPath -eq 'ComputerName' }
            $CnParam.DefaultValue.Extent.Text | Should -Match '\$env:'
        }
    }
}
