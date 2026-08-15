function Get-USBHistory {
    param (
        [string]$CsvPath = ""
    )

    try {
        $usbStorPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"

        if (-not (Test-Path $usbStorPath)) {
            $results = [PSCustomObject]@{
                Device = "-"
                Status = "No USB storage device history found"
            }
        } else {
            $results = @()
            foreach ($deviceKey in (Get-ChildItem -Path $usbStorPath -ErrorAction SilentlyContinue)) {
                foreach ($instanceKey in (Get-ChildItem -Path $deviceKey.PSPath -ErrorAction SilentlyContinue)) {
                    $props = Get-ItemProperty -Path $instanceKey.PSPath -ErrorAction SilentlyContinue
                    $results += [PSCustomObject]@{
                        Device       = if ($props.FriendlyName) { $props.FriendlyName } else { $deviceKey.PSChildName }
                        DeviceID     = $deviceKey.PSChildName
                        SerialNumber = $instanceKey.PSChildName
                        Status       = "Historical USB storage device"
                    }
                }
            }

            if ($results.Count -eq 0) {
                $results = [PSCustomObject]@{
                    Device = "-"
                    Status = "No USB storage device history found"
                }
            }
        }

        if ($CsvPath) {
            $results | Export-Csv -Path $CsvPath -NoTypeInformation
            Write-Host "USB history exported to: $CsvPath"
        }

        return $results
    } catch {
        Write-Warning "Could not retrieve USB history: $_"
        $result = [PSCustomObject]@{
            Error = "Could not retrieve USB history: $($_.Exception.Message)"
            Timestamp = Get-Date
        }

        if ($CsvPath) {
            $result | Export-Csv -Path $CsvPath -NoTypeInformation
        }

        return $result
    }
}
