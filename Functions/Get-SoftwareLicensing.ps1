function Get-SoftwareLicensing {
    Write-Host "Gathering Software Licensing Information..."

    $osLicense = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.ApplicationID -like "*Windows*" } | Select-Object Name, LicenseStatus
    $officeLicense = Get-CimInstance SoftwareLicensingProduct | Where-Object { $_.Name -like "*Office*" } | Select-Object Name, LicenseStatus

    return [PSCustomObject]@{
        OSLicense = $osLicense
        OfficeLicense = $officeLicense
    }
}
