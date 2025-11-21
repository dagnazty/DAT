# Remote System Auditing Function
# Allows running DAT audits on remote computers

function Invoke-RemoteAudit {
    <#
    .SYNOPSIS
    Runs DAT audit functions on remote computers.
    
    .DESCRIPTION
    Executes specified audit functions on one or more remote computers using PowerShell remoting.
    Requires WinRM to be enabled on target systems.
    
    .PARAMETER ComputerName
    One or more computer names or IP addresses to audit.
    
    .PARAMETER AuditFunctions
    Array of audit function names to run (e.g., "Get-SystemUptime", "Get-SecurityUpdateStatus").
    
    .PARAMETER Credential
    PSCredential object for authentication. If not provided, uses current user context.
    
    .PARAMETER CsvPath
    Optional path to export results to CSV.
    
    .PARAMETER Parallel
    Run audits on multiple computers in parallel (default: $true).
    
    .EXAMPLE
    Invoke-RemoteAudit -ComputerName "SERVER01" -AuditFunctions @("Get-SystemUptime", "Get-SecurityUpdateStatus")
    
    .EXAMPLE
    $cred = Get-Credential
    Invoke-RemoteAudit -ComputerName "SERVER01","SERVER02" -AuditFunctions @("Get-SystemUptime") -Credential $cred -CsvPath "remote_audit.csv"
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory=$true)]
        [string[]]$AuditFunctions,
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory=$false)]
        [string]$CsvPath = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$Parallel = $true
    )
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "  Remote Audit Execution" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    $results = @()
    $scriptPath = Split-Path -Parent $PSScriptRoot
    
    # Test connectivity first
    Write-Host "Testing connectivity to remote systems..." -ForegroundColor Yellow
    $reachableComputers = @()
    foreach ($computer in $ComputerName) {
        if (Test-Connection -ComputerName $computer -Count 1 -Quiet) {
            Write-Host "  [OK] $computer is reachable" -ForegroundColor Green
            $reachableComputers += $computer
        } else {
            Write-Host "  [FAIL] $computer is not reachable" -ForegroundColor Red
            $results += [PSCustomObject]@{
                ComputerName = $computer
                AuditFunction = "N/A"
                Status = "Unreachable"
                Data = "Computer did not respond to ping"
                Timestamp = Get-Date
            }
        }
    }
    
    if ($reachableComputers.Count -eq 0) {
        Write-Host ""
        Write-Host "No reachable computers found. Exiting." -ForegroundColor Red
        return $results
    }
    
    Write-Host ""
    Write-Host "Running audits on $($reachableComputers.Count) computer(s)..." -ForegroundColor Yellow
    Write-Host ""
    
    # Create script block for remote execution
    $scriptBlock = {
        param($FunctionName, $FunctionsPath)
        
        try {
            # Load the function
            $functionFile = Join-Path -Path $FunctionsPath -ChildPath "$FunctionName.ps1"
            if (Test-Path $functionFile) {
                . $functionFile
                
                # Execute the function
                $result = & $FunctionName
                
                return @{
                    Status = "Success"
                    Data = $result
                }
            } else {
                return @{
                    Status = "Error"
                    Data = "Function file not found: $functionFile"
                }
            }
        } catch {
            return @{
                Status = "Error"
                Data = $_.Exception.Message
            }
        }
    }
    
    # Execute audits
    foreach ($computer in $reachableComputers) {
        Write-Host "Auditing $computer..." -ForegroundColor Cyan
        
        foreach ($funcName in $AuditFunctions) {
            Write-Host "  - Running $funcName..." -ForegroundColor Gray
            
            try {
                $invokeParams = @{
                    ComputerName = $computer
                    ScriptBlock = $scriptBlock
                    ArgumentList = @($funcName, (Join-Path -Path $scriptPath -ChildPath "Functions"))
                }
                
                if ($Credential) {
                    $invokeParams.Credential = $Credential
                }
                
                $remoteResult = Invoke-Command @invokeParams -ErrorAction Stop
                
                $results += [PSCustomObject]@{
                    ComputerName = $computer
                    AuditFunction = $funcName
                    Status = $remoteResult.Status
                    Data = $remoteResult.Data
                    Timestamp = Get-Date
                }
                
                if ($remoteResult.Status -eq "Success") {
                    Write-Host "    [OK] Completed successfully" -ForegroundColor Green
                } else {
                    Write-Host "    [ERROR] $($remoteResult.Data)" -ForegroundColor Red
                }
                
            } catch {
                Write-Host "    [ERROR] $_" -ForegroundColor Red
                $results += [PSCustomObject]@{
                    ComputerName = $computer
                    AuditFunction = $funcName
                    Status = "Error"
                    Data = $_.Exception.Message
                    Timestamp = Get-Date
                }
            }
        }
        Write-Host ""
    }
    
    # Export results if requested
    if ($CsvPath) {
        try {
            $results | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "Results exported to: $CsvPath" -ForegroundColor Green
        } catch {
            Write-Host "Failed to export results: $_" -ForegroundColor Red
        }
    }
    
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Remote audit completed!" -ForegroundColor Cyan
    Write-Host "Total systems audited: $($reachableComputers.Count)" -ForegroundColor Cyan
    Write-Host "Total checks performed: $($results.Count)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    return $results
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name -or $MyInvocation.Line -match '^\.\s') {
    Write-Host "Remote Audit Tool" -ForegroundColor Cyan
    Write-Host "Usage: Invoke-RemoteAudit -ComputerName 'SERVER01' -AuditFunctions @('Get-SystemUptime')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Prerequisites:" -ForegroundColor Yellow
    Write-Host "  1. WinRM must be enabled on target systems" -ForegroundColor Gray
    Write-Host "  2. You must have admin rights on target systems" -ForegroundColor Gray
    Write-Host "  3. Firewall must allow WinRM (port 5985/5986)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To enable WinRM on target systems, run:" -ForegroundColor Yellow
    Write-Host "  Enable-PSRemoting -Force" -ForegroundColor Gray
    Write-Host ""
}
