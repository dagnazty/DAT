function Test-Compliance {
    param (
        [string[]]$Standards = @("CIS", "NIST"),
        [string]$CsvPath
    )

    $results = @()

    # Helper function to add result
    function Add-Result {
        param($Check, $Expected, $Actual, $Status, $Standard)
        $results += [PSCustomObject]@{
            Check     = $Check
            Expected  = $Expected
            Actual    = $Actual
            Status    = $Status
            Standard  = $Standard
            Timestamp = Get-Date
        }
    }

    # 1. Firewall Status
    try {
        $firewall = Get-NetFirewallProfile -ErrorAction Stop
        foreach ($profile in $firewall) {
            $status = if ($profile.Enabled) { "Pass" } else { "Fail" }
            Add-Result -Check "Firewall Profile: $($profile.Name)" -Expected "True" -Actual $profile.Enabled -Status $status -Standard "CIS"
        }
    }
    catch {
        Add-Result -Check "Firewall Status" -Expected "Enabled" -Actual "Error: $_" -Status "Fail" -Standard "CIS"
    }

    # 2. Windows Update Service
    try {
        $wua = Get-Service -Name wuauserv -ErrorAction Stop
        $status = if ($wua.Status -eq "Running") { "Pass" } else { "Fail" }
        Add-Result -Check "Windows Update Service" -Expected "Running" -Actual $wua.Status -Status $status -Standard "NIST"
    }
    catch {
        Add-Result -Check "Windows Update Service" -Expected "Running" -Actual "Not Found" -Status "Fail" -Standard "NIST"
    }

    # 3. Windows Defender
    try {
        $defender = Get-Service -Name WinDefend -ErrorAction Stop
        $status = if ($defender.Status -eq "Running") { "Pass" } else { "Fail" }
        Add-Result -Check "Windows Defender Service" -Expected "Running" -Actual $defender.Status -Status $status -Standard "CIS"
    }
    catch {
        Add-Result -Check "Windows Defender Service" -Expected "Running" -Actual "Not Found" -Status "Fail" -Standard "CIS"
    }

    # 4. UAC Status (Registry Check)
    try {
        $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        $uac = Get-ItemProperty -Path $uacPath -Name "EnableLUA" -ErrorAction Stop
        $status = if ($uac.EnableLUA -eq 1) { "Pass" } else { "Fail" }
        Add-Result -Check "User Account Control (UAC)" -Expected "1" -Actual $uac.EnableLUA -Status $status -Standard "NIST"
    }
    catch {
        Add-Result -Check "User Account Control (UAC)" -Expected "1" -Actual "Error" -Status "Fail" -Standard "NIST"
    }

    # Calculate Summary
    $totalChecks = $results.Count
    $passedChecks = ($results | Where-Object { $_.Status -eq "Pass" }).Count
    $complianceScore = if ($totalChecks -gt 0) { [math]::Round(($passedChecks / $totalChecks) * 100, 2) } else { 0 }

    # Add Summary Object (required by GUI)
    $results += [PSCustomObject]@{
        Standard             = "SUMMARY"
        CompliancePercentage = $complianceScore
        CurrentValue         = "$passedChecks / $totalChecks"
        Check                = "Overall Compliance"
        Status               = if ($complianceScore -ge 80) { "Pass" } else { "Fail" }
    }

    if ($CsvPath) {
        $results | Export-Csv -Path $CsvPath -NoTypeInformation
    }

    return $results
}
