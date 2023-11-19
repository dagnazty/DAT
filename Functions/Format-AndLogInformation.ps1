function Format-AndLogInformation {
    param (
        [Parameter(Mandatory)]
        [PSCustomObject]$AuditData,
        [Parameter(Mandatory)]
        [string]$LogFilePath
    )

    $directory = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }

    $sb = New-Object System.Text.StringBuilder

    foreach ($property in $AuditData.PSObject.Properties) {
        [void]$sb.AppendLine("`n=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $($property.Name) ===")
        $formattedTable = $AuditData."$($property.Name)" | Format-Table | Out-String
        [void]$sb.AppendLine($formattedTable)
    }

    $sb.ToString() | Out-File -FilePath $LogFilePath -Append

    Write-Host $sb.ToString()
}
