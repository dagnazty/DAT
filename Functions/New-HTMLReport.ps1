function New-HTMLReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$AuditData,

        [string]$CompanyName = "DAT Audit Tool"
    )

    $css = @"
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: #f4f4f4; color: #333; }
        header { background-color: #007bbf; color: white; padding: 20px; text-align: center; }
        h1 { margin: 0; }
        .container { max-width: 1200px; margin: 20px auto; padding: 20px; background: white; box-shadow: 0 0 10px rgba(0,0,0,0.1); border-radius: 5px; }
        .section { margin-bottom: 30px; border-bottom: 1px solid #eee; padding-bottom: 20px; }
        .section h2 { color: #007bbf; border-left: 5px solid #007bbf; padding-left: 10px; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 0.9em; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f8f9fa; font-weight: bold; color: #555; }
        tr:hover { background-color: #f1f1f1; }
        .timestamp { text-align: right; color: #777; font-size: 0.8em; margin-top: -10px; margin-bottom: 20px; }
        .status-success { color: green; font-weight: bold; }
        .status-error { color: red; font-weight: bold; }
        .footer { text-align: center; padding: 20px; color: #777; font-size: 0.8em; }
    </style>
"@

    $htmlBuilder = [System.Text.StringBuilder]::new()
    [void]$htmlBuilder.AppendLine("<!DOCTYPE html>")
    [void]$htmlBuilder.AppendLine("<html>")
    [void]$htmlBuilder.AppendLine("<head>")
    [void]$htmlBuilder.AppendLine("    <title>$CompanyName - Audit Report</title>")
    [void]$htmlBuilder.AppendLine($css)
    [void]$htmlBuilder.AppendLine("</head>")
    [void]$htmlBuilder.AppendLine("<body>")
    
    # Header
    [void]$htmlBuilder.AppendLine("<header>")
    [void]$htmlBuilder.AppendLine("    <h1>$CompanyName - System Audit Report</h1>")
    [void]$htmlBuilder.AppendLine("</header>")

    [void]$htmlBuilder.AppendLine("<div class='container'>")
    [void]$htmlBuilder.AppendLine("    <div class='timestamp'>Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div>")

    # Process each audit result
    foreach ($key in $AuditData.Keys) {
        $data = $AuditData[$key]
        
        [void]$htmlBuilder.AppendLine("    <div class='section'>")
        [void]$htmlBuilder.AppendLine("        <h2>$key</h2>")

        if ($null -eq $data) {
            [void]$htmlBuilder.AppendLine("        <p>No data available.</p>")
        }
        elseif ($data -is [string]) {
             [void]$htmlBuilder.AppendLine("        <p>$data</p>")
        }
        elseif ($data -is [System.Collections.IEnumerable] -and $data -isnot [string]) {
            # It's a collection (array/list)
            $items = @($data)
            if ($items.Count -gt 0) {
                # Get properties from the first object to build table headers
                $firstItem = $items[0]
                if ($firstItem -is [PSCustomObject] -or $firstItem -is [System.Management.Automation.PSObject]) {
                    $props = $firstItem.PSObject.Properties.Name
                    
                    [void]$htmlBuilder.AppendLine("        <table>")
                    [void]$htmlBuilder.AppendLine("            <thead><tr>")
                    foreach ($prop in $props) {
                        [void]$htmlBuilder.AppendLine("                <th>$prop</th>")
                    }
                    [void]$htmlBuilder.AppendLine("            </tr></thead>")
                    [void]$htmlBuilder.AppendLine("            <tbody>")
                    
                    foreach ($item in $items) {
                        [void]$htmlBuilder.AppendLine("            <tr>")
                        foreach ($prop in $props) {
                            $val = $item.$prop
                            if ($val -is [DateTime]) { $val = $val.ToString("yyyy-MM-dd HH:mm:ss") }
                            [void]$htmlBuilder.AppendLine("                <td>$($val)</td>")
                        }
                        [void]$htmlBuilder.AppendLine("            </tr>")
                    }
                    [void]$htmlBuilder.AppendLine("            </tbody>")
                    [void]$htmlBuilder.AppendLine("        </table>")
                } else {
                     # Simple list of strings/objects
                     [void]$htmlBuilder.AppendLine("        <ul>")
                     foreach ($item in $items) {
                         [void]$htmlBuilder.AppendLine("            <li>$item</li>")
                     }
                     [void]$htmlBuilder.AppendLine("        </ul>")
                }
            } else {
                [void]$htmlBuilder.AppendLine("        <p>No items found.</p>")
            }
        }
        else {
            # Single Object
            if ($data -is [PSCustomObject] -or $data -is [System.Management.Automation.PSObject]) {
                $props = $data.PSObject.Properties.Name
                [void]$htmlBuilder.AppendLine("        <table>")
                foreach ($prop in $props) {
                    [void]$htmlBuilder.AppendLine("            <tr><th>$prop</th><td>$($data.$prop)</td></tr>")
                }
                [void]$htmlBuilder.AppendLine("        </table>")
            } else {
                [void]$htmlBuilder.AppendLine("        <p>$data</p>")
            }
        }
        
        [void]$htmlBuilder.AppendLine("    </div>")
    }

    [void]$htmlBuilder.AppendLine("</div>") # End container
    
    [void]$htmlBuilder.AppendLine("<div class='footer'>Generated by DAT Advanced Audit Tool</div>")
    [void]$htmlBuilder.AppendLine("</body>")
    [void]$htmlBuilder.AppendLine("</html>")

    $htmlBuilder.ToString() | Out-File -FilePath $OutputPath -Encoding UTF8
}
