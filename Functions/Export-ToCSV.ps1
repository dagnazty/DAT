function Export-ToCSV {
    param (
        [Parameter(Mandatory)]
        $Data,
        [Parameter(Mandatory)]
        [string]$FilePath,
        [string]$SectionName = ""
    )

    # Create directory if it doesn't exist
    $directory = Split-Path -Path $FilePath -Parent
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    # Handle different data types
    if ($Data -is [PSCustomObject] -and $Data.PSObject.Properties.Count -gt 0) {
        # Check if it's a complex object with multiple sections
        $properties = $Data.PSObject.Properties
        $hasMultipleSections = $false

        foreach ($prop in $properties) {
            if ($prop.Value -is [System.Collections.IEnumerable] -and $prop.Value -isnot [string]) {
                $hasMultipleSections = $true
                break
            }
        }

        if ($hasMultipleSections) {
            # Export each section to a separate CSV file
            foreach ($prop in $properties) {
                $sectionData = $prop.Value
                if ($sectionData -is [System.Collections.IEnumerable] -and $sectionData -isnot [string]) {
                    if ($SectionName) {
                        $sectionFileName = "$SectionName`_$($prop.Name).csv"
                    } else {
                        $sectionFileName = "$($prop.Name).csv"
                    }
                    $sectionFilePath = Join-Path -Path $directory -ChildPath $sectionFileName
                    $sectionData | Export-Csv -Path $sectionFilePath -NoTypeInformation
                    Write-Host "Exported $($prop.Name) to: $sectionFilePath"
                } else {
                    if ($SectionName) {
                        $sectionFileName = "$SectionName`_$($prop.Name).csv"
                    } else {
                        $sectionFileName = "$($prop.Name).csv"
                    }
                    $sectionFilePath = Join-Path -Path $directory -ChildPath $sectionFileName
                    $sectionData | Export-Csv -Path $sectionFilePath -NoTypeInformation
                    Write-Host "Exported $($prop.Name) to: $sectionFilePath"
                }
            }
        } else {
            # Simple object, export directly
            $Data | Export-Csv -Path $FilePath -NoTypeInformation
            Write-Host "Exported to: $FilePath"
        }
    } elseif ($Data -is [System.Collections.IEnumerable] -and $Data -isnot [string]) {
        # Array of objects
        $Data | Export-Csv -Path $FilePath -NoTypeInformation
        Write-Host "Exported to: $FilePath"
    } else {
        # Single value, create a simple CSV
        [PSCustomObject]@{Value = $Data} | Export-Csv -Path $FilePath -NoTypeInformation
        Write-Host "Exported to: $FilePath"
    }
}

function Invoke-StandaloneFunction {
    param (
        [Parameter(Mandatory)]
        [scriptblock]$FunctionScript,
        [string]$CsvPath = "",
        [string]$SectionName = ""
    )

    try {
        # Execute the function
        $result = & $FunctionScript

        # If CSV path is provided, export to CSV
        if ($CsvPath) {
            Export-ToCSV -Data $result -FilePath $CsvPath -SectionName $SectionName
        }

        # Return the result for display or further processing
        return $result
    }
    catch {
        Write-Error "Error executing function: $_"
        throw
    }
}
