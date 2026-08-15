function New-HTMLReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$AuditData,

        [string]$CompanyName = "DAT Audit Tool"
    )

    # Reaper theme palette (matches the GUI)
    $css = @"
    <style>
        :root {
            --bg: #0c0c0e; --panel: #17171b; --field: #202025;
            --border: #404046; --line: #2a2a2f;
            --bone: #ece9e2; --dim: #94928c; --blood: #d4494f;
        }
        * { box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 0; background-color: var(--bg); color: var(--bone); }
        header { background-color: #050506; padding: 18px 32px; display: flex; align-items: center; gap: 20px; border-bottom: 2px solid var(--bone); }
        header img.logo { width: 56px; height: 56px; }
        header h1 { margin: 0; font-size: 1.6em; letter-spacing: 2px; text-transform: uppercase; }
        header .sub { color: var(--dim); font-size: 0.8em; letter-spacing: 3px; text-transform: uppercase; margin-top: 4px; }
        .container { max-width: 1200px; margin: 24px auto; padding: 24px; background: var(--panel); border: 1px solid var(--border); }
        .section { margin-bottom: 32px; border-bottom: 1px solid var(--line); padding-bottom: 22px; }
        .section:last-child { border-bottom: none; }
        .section h2 { color: var(--bone); border-left: 4px solid var(--bone); padding-left: 12px; font-size: 1.1em; letter-spacing: 1px; text-transform: uppercase; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 0.85em; }
        th, td { padding: 9px 12px; text-align: left; border-bottom: 1px solid var(--line); }
        th { background-color: var(--bg); font-weight: bold; color: var(--dim); text-transform: uppercase; font-size: 0.85em; letter-spacing: 1px; }
        tr:hover td { background-color: var(--field); }
        .timestamp { text-align: right; color: var(--dim); font-size: 0.8em; margin-bottom: 20px; }
        .ok { color: var(--dim); }
        .bad { color: var(--blood); font-weight: bold; }
        .status-success { color: var(--dim); font-weight: bold; }
        .status-error { color: var(--blood); font-weight: bold; }
        ul { margin: 8px 0; padding-left: 22px; }
        .footer { text-align: center; padding: 20px; color: var(--dim); font-size: 0.8em; letter-spacing: 2px; text-transform: uppercase; }
        @media print {
            body { background-color: #fff; color: #121214; }
            .container { border: none; background: #fff; }
            header { background-color: #fff; border-bottom-color: #121214; }
            header h1, .section h2 { color: #121214; }
            .section h2 { border-left-color: #121214; }
            th { background-color: #f0efec; color: #69675f; }
        }
    </style>
"@

    # Value-based cell styling: blood red for findings, dim for healthy
    $badPattern = '^(FAIL|DISABLED|NOT PROTECTED|REBOOT PENDING|EXPIRED|EXPIRING SOON|CRITICAL|WARNING|ENABLED \(RISK\))$'
    $okPattern = '^(OK|Enabled|Success|Disabled \(good\))$'

    function Get-CellHtml {
        param($Value)
        if ($Value -is [DateTime]) { $Value = $Value.ToString("yyyy-MM-dd HH:mm:ss") }
        $text = [System.Net.WebUtility]::HtmlEncode("$Value")
        $cls = ""
        if ("$Value" -match $badPattern) { $cls = " class='bad'" }
        elseif ("$Value" -match $okPattern) { $cls = " class='ok'" }
        return "<td$cls>$text</td>"
    }

    # Embed the skull mark as a data URI so the report is self-contained
    $logoTag = ""
    $logoPath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Assets\dat_logo_small.png"
    if (Test-Path $logoPath) {
        try {
            $logoB64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($logoPath))
            $logoTag = "<img class='logo' src='data:image/png;base64,$logoB64' alt='DAT'>"
        }
        catch { }
    }

    $htmlBuilder = [System.Text.StringBuilder]::new()
    [void]$htmlBuilder.AppendLine("<!DOCTYPE html>")
    [void]$htmlBuilder.AppendLine("<html>")
    [void]$htmlBuilder.AppendLine("<head>")
    [void]$htmlBuilder.AppendLine("    <meta charset='utf-8'>")
    [void]$htmlBuilder.AppendLine("    <title>$CompanyName - Audit Report</title>")
    [void]$htmlBuilder.AppendLine($css)
    [void]$htmlBuilder.AppendLine("</head>")
    [void]$htmlBuilder.AppendLine("<body>")

    # Header
    [void]$htmlBuilder.AppendLine("<header>")
    [void]$htmlBuilder.AppendLine("    $logoTag")
    [void]$htmlBuilder.AppendLine("    <div>")
    [void]$htmlBuilder.AppendLine("        <h1>DAG'S AUDIT TOOL</h1>")
    [void]$htmlBuilder.AppendLine("        <div class='sub'>System Audit Report // $([System.Net.WebUtility]::HtmlEncode($CompanyName)) // $env:COMPUTERNAME</div>")
    [void]$htmlBuilder.AppendLine("    </div>")
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
            [void]$htmlBuilder.AppendLine("        <p>$([System.Net.WebUtility]::HtmlEncode($data))</p>")
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
                        [void]$htmlBuilder.AppendLine("                <th>$([System.Net.WebUtility]::HtmlEncode($prop))</th>")
                    }
                    [void]$htmlBuilder.AppendLine("            </tr></thead>")
                    [void]$htmlBuilder.AppendLine("            <tbody>")

                    foreach ($item in $items) {
                        [void]$htmlBuilder.AppendLine("            <tr>")
                        foreach ($prop in $props) {
                            [void]$htmlBuilder.AppendLine("                $(Get-CellHtml -Value $item.$prop)")
                        }
                        [void]$htmlBuilder.AppendLine("            </tr>")
                    }
                    [void]$htmlBuilder.AppendLine("            </tbody>")
                    [void]$htmlBuilder.AppendLine("        </table>")
                }
                else {
                    # Simple list of strings/objects
                    [void]$htmlBuilder.AppendLine("        <ul>")
                    foreach ($item in $items) {
                        [void]$htmlBuilder.AppendLine("            <li>$([System.Net.WebUtility]::HtmlEncode("$item"))</li>")
                    }
                    [void]$htmlBuilder.AppendLine("        </ul>")
                }
            }
            else {
                [void]$htmlBuilder.AppendLine("        <p>No items found.</p>")
            }
        }
        else {
            # Single Object
            if ($data -is [PSCustomObject] -or $data -is [System.Management.Automation.PSObject]) {
                $props = $data.PSObject.Properties.Name
                [void]$htmlBuilder.AppendLine("        <table>")
                foreach ($prop in $props) {
                    [void]$htmlBuilder.AppendLine("            <tr><th>$([System.Net.WebUtility]::HtmlEncode($prop))</th>$(Get-CellHtml -Value $data.$prop)</tr>")
                }
                [void]$htmlBuilder.AppendLine("        </table>")
            }
            else {
                [void]$htmlBuilder.AppendLine("        <p>$([System.Net.WebUtility]::HtmlEncode("$data"))</p>")
            }
        }

        [void]$htmlBuilder.AppendLine("    </div>")
    }

    [void]$htmlBuilder.AppendLine("</div>") # End container

    [void]$htmlBuilder.AppendLine("<div class='footer'>Generated by DAT - dag's Audit Tool</div>")
    [void]$htmlBuilder.AppendLine("</body>")
    [void]$htmlBuilder.AppendLine("</html>")

    $htmlBuilder.ToString() | Out-File -FilePath $OutputPath -Encoding UTF8
}
