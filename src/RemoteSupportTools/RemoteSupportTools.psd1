@{
    RootModule        = 'RemoteSupportTools.psm1'
    ModuleVersion      = '0.1.0'
    GUID               = 'aa004c82-368d-4a22-a548-47ca5a811bd7'
    Author             = 'Junior'
    Description        = 'Ferramentas de suporte remoto via WinRM para ambiente Entra ID joined'
    PowerShellVersion  = '5.1'
    FunctionsToExport  = @('Test-WinRMStatus', 'Enable-RemoteWinRM')
}
