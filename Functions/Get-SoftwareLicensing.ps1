function Get-SoftwareLicensing {
    param (
        [string]$CsvPath = ""
    )

    Write-Host "Gathering Software Licensing Information..."

    $osLicense = Get-CimInstance SoftwareLicensingProduct -ErrorAction SilentlyContinue |
        Where-Object { $_.ApplicationID -like "*Windows*" } |
        Select-Object Name,
            @{Name="LicenseStatusText"; Expression={switch ($_.LicenseStatus) {
                0 {"Unlicensed"}
                1 {"Licensed"}
                2 {"Out-Of-Box-Grace-Period"}
                3 {"Out-Of-Tolerance-Grace-Period"}
                4 {"Non-Genuine-Grace-Period"}
                5 {"Notification"}
                6 {"Extended-Grace"}
                default {"Unknown"}
            }}},
            LicenseStatus,
            ProductKeyID,
            ProductKeyID2

    $officeLicense = Get-CimInstance SoftwareLicensingProduct -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "*Office*" } |
        Select-Object Name,
            @{Name="LicenseStatusText"; Expression={switch ($_.LicenseStatus) {
                0 {"Unlicensed"}
                1 {"Licensed"}
                2 {"Out-Of-Box-Grace-Period"}
                3 {"Out-Of-Tolerance-Grace-Period"}
                4 {"Non-Genuine-Grace-Period"}
                5 {"Notification"}
                6 {"Extended-Grace"}
                default {"Unknown"}
            }}},
            LicenseStatus,
            ProductKeyID,
            ProductKeyID2

    $result = [PSCustomObject]@{
        OSLicense = $osLicense
        OfficeLicense = $officeLicense
    }

    if ($CsvPath) {
        # Create directory if it doesn't exist
        $directory = Split-Path -Path $CsvPath -Parent
        if ([string]::IsNullOrEmpty($directory)) {
            $directory = "."
        }
        if (-not (Test-Path -Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }

        # Export each license type to separate CSV files
        if ($osLicense) {
            $osLicensePath = Join-Path -Path $directory -ChildPath "SoftwareLicensing_OS.csv"
            $osLicense | Export-Csv -Path $osLicensePath -NoTypeInformation
            Write-Host "Exported OS licensing to: $osLicensePath"
        }

        if ($officeLicense) {
            $officeLicensePath = Join-Path -Path $directory -ChildPath "SoftwareLicensing_Office.csv"
            $officeLicense | Export-Csv -Path $officeLicensePath -NoTypeInformation
            Write-Host "Exported Office licensing to: $officeLicensePath"
        }
    }

    return $result
}

# Standalone execution
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    param (
        [string]$CsvPath = ""
    )
    Get-SoftwareLicensing -CsvPath $CsvPath
}
