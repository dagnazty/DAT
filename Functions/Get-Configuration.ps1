function Get-Configuration {
    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Config\DefaultConfig.json"
    
    if (Test-Path $configPath) {
        try {
            $jsonContent = Get-Content -Path $configPath -Raw -ErrorAction Stop
            $config = $jsonContent | ConvertFrom-Json
            return $config
        }
        catch {
            Write-Warning "Failed to load configuration from $configPath : $_"
            return $null
        }
    }
    else {
        Write-Warning "Configuration file not found at $configPath"
        return $null
    }
}
