function Get-PluginRoot {
    return Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Plugins"
}

function Get-AvailablePlugins {
    $pluginRoot = Get-PluginRoot

    if (-not (Test-Path $pluginRoot)) {
        return @()
    }

    $plugins = @()
    foreach ($file in (Get-ChildItem -Path "$pluginRoot\*.ps1" -ErrorAction SilentlyContinue)) {
        if ($file.Length -eq 0) { continue }

        $raw = Get-Content -Path $file.FullName -Raw
        $description = "No description"
        if ($raw -match '(?ms)^\s*\.DESCRIPTION\s*\r?\n\s*(.+?)\r?\n') {
            $description = $Matches[1].Trim()
        }

        $plugins += [PSCustomObject]@{
            Name        = $file.BaseName
            Description = $description
            Path        = $file.FullName
        }
    }

    return $plugins
}

function Invoke-Plugin {
    param (
        [Parameter(Mandatory)]
        [string]$PluginName,

        [hashtable]$Parameters = @{}
    )

    $pluginRoot = Get-PluginRoot
    $pluginPath = Join-Path -Path $pluginRoot -ChildPath "$PluginName.ps1"

    if (-not (Test-Path $pluginPath)) {
        throw "Plugin '$PluginName' not found at $pluginPath"
    }

    return & $pluginPath -Parameters $Parameters
}

function New-PluginTemplate {
    param (
        [Parameter(Mandatory)]
        [string]$PluginName,

        [string]$Description = "Custom DAT plugin"
    )

    $pluginRoot = Get-PluginRoot
    if (-not (Test-Path $pluginRoot)) {
        New-Item -ItemType Directory -Path $pluginRoot -Force | Out-Null
    }

    $pluginPath = Join-Path -Path $pluginRoot -ChildPath "$PluginName.ps1"
    if (Test-Path $pluginPath) {
        throw "Plugin '$PluginName' already exists at $pluginPath"
    }

    $template = @"
<#
.SYNOPSIS
$PluginName

.DESCRIPTION
$Description
#>
param (
    [hashtable]`$Parameters = @{}
)

# Return objects (or strings) - the GUI displays whatever you output.
[PSCustomObject]@{
    Plugin    = "$PluginName"
    Timestamp = Get-Date
    Result    = "Implement your custom audit logic here"
}
"@

    Set-Content -Path $pluginPath -Value $template -Encoding Ascii
    Write-Host "Plugin template created: $pluginPath"
    return $pluginPath
}
