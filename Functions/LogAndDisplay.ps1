function LogAndDisplay {
    param (
        [Parameter(Mandatory)]
        $Data
    )

    if ($Data -is [System.Collections.IEnumerable] -and $Data -isnot [string]) {
        foreach ($item in $Data) {
            $itemString = $item | Format-List | Out-String -Width 4096
            Add-Content -Path $LogFilePath -Value $itemString
            Write-Host $itemString
        }
    } else {
        $dataString = $Data | Format-List | Out-String -Width 4096
        Add-Content -Path $LogFilePath -Value $dataString
        Write-Host $dataString
    }
}
