function Set-Configuration {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Configuration
    )
    
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Config\DefaultConfig.json"
    
    try {
        $jsonContent = $Configuration | ConvertTo-Json -Depth 10
        Set-Content -Path $configPath -Value $jsonContent -ErrorAction Stop
        Write-Host "Configuration saved successfully to $configPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Warning "Failed to save configuration to $configPath : $_"
        return $false
    }
}
