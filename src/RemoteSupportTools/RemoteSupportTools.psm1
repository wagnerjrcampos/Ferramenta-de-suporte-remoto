$Public = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)

foreach ($Function in $Public) {
    try {
        . $Function.FullName
    } catch {
        Write-Error "Falha ao importar $($Function.FullName): $_"
    }
}

Export-ModuleMember -Function $Public.BaseName
