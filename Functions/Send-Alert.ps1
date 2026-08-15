function Send-Alert {
    param (
        [Parameter(Mandatory)]
        [string]$Subject,
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet("Email", "Webhook", "EventLog")]
        [string[]]$Channels = @("EventLog"),
        [ValidateSet("Critical", "Warning", "Info")]
        [string]$Severity = "Info",
        [string[]]$Attachments = @(),
        [PSCustomObject]$Config = $null
    )
    
    # Load configuration if not provided
    if ($null -eq $Config) {
        try {
            if (Get-Command -Name Get-Configuration -ErrorAction SilentlyContinue) {
                $Config = Get-Configuration
            }
        }
        catch {
            # Configuration not available, continue without it
        }
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $hostname = $env:COMPUTERNAME

    Write-Host "[$timestamp] Sending $Severity alert: $Subject"

    # Event Log (always available)
    if ($Channels -contains "EventLog") {
        try {
            $eventMessage = @"
Subject: $Subject
Message: $Message
Severity: $Severity
Host: $hostname
Timestamp: $timestamp
"@
            Write-EventLog -LogName "Application" -Source "DAT" -EventId 1000 -EntryType $Severity -Message $eventMessage -ErrorAction Stop
            Write-Host "Alert logged to Event Log"
        }
        catch {
            # Create event source if it doesn't exist
            try {
                # Check if we are running as admin before attempting to create source
                $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
                $isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole($adminRole)
                
                if ($isElevated) {
                    if (-not ([System.Diagnostics.EventLog]::SourceExists("DAT"))) {
                        New-EventLog -LogName "Application" -Source "DAT" -ErrorAction Stop
                    }
                    Write-EventLog -LogName "Application" -Source "DAT" -EventId 1000 -EntryType $Severity -Message $eventMessage
                    Write-Host "Alert logged to Event Log"
                }
                else {
                    Write-Warning "Could not write to Event Log: Source 'DAT' does not exist and script is not running as Administrator to create it."
                }
            }
            catch {
                Write-Warning "Could not write to Event Log: $_"
            }
        }
    }

    # Email alerts
    if ($Channels -contains "Email" -and $Config -and $Config.alerting.email) {
        try {
            $emailConfig = $Config.alerting.email

            # Modern providers (iCloud, Gmail, Outlook) require TLS 1.2.
            # Windows PowerShell 5.1 defaults to TLS 1.0, which they reject
            # outright - so force 1.2 before opening the connection.
            [System.Net.ServicePointManager]::SecurityProtocol = `
                [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

            # Load saved credential (DPAPI-encrypted PSCredential) if present.
            # iCloud/Gmail/Outlook will not relay without an authenticated login.
            $credential = $null
            if ($emailConfig.credentialPath -and (Test-Path $emailConfig.credentialPath)) {
                $credential = Import-Clixml -Path $emailConfig.credentialPath
            }

            # STARTTLS on (default on for hosted providers). Port 587 is the
            # STARTTLS submission port; fall back to 25 only for plain relays.
            $useSsl = if ($null -ne $emailConfig.useSSL) { [bool]$emailConfig.useSSL } else { $true }
            $port = if ($emailConfig.port) { [int]$emailConfig.port } elseif ($useSsl) { 587 } else { 25 }

            # From must be a mailbox the server accepts. For iCloud/Gmail that
            # means the account address (or a verified alias) - never a made-up
            # DAT@HOSTNAME address, which providers reject as spoofing.
            $fromAddress = if ($emailConfig.from) {
                $emailConfig.from
            }
            elseif ($credential) {
                $credential.UserName
            }
            elseif ($emailConfig.to) {
                @($emailConfig.to)[0]
            }
            else {
                "DAT@$env:COMPUTERNAME"
            }

            if (-not $emailConfig.smtpServer) { throw "No SMTP server configured." }
            if (-not $emailConfig.to) { throw "No recipient (To) address configured." }
            if ($useSsl -and -not $credential) {
                throw "SMTP requires a saved credential. iCloud/Gmail/Outlook need an app-specific password - set the SMTP username and app password in Settings and save."
            }

            # Validate address formats up front. Send-MailMessage's native error
            # ("not in the form required for an e-mail address") never says which
            # field is wrong - so name it and say what a valid value looks like.
            if ($fromAddress -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
                throw "The 'From' value '$fromAddress' is not a valid email address. Set 'From' (or the SMTP username) to a full address like you@icloud.com."
            }
            foreach ($recip in @($emailConfig.to)) {
                if ("$recip".Trim() -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
                    throw "The recipient '$recip' is not a valid email address. Use full addresses separated by ; in the 'To' field."
                }
            }

            $emailParams = @{
                From        = $fromAddress
                To          = @($emailConfig.to)
                Subject     = "DAT Alert: $Subject"
                Body        = @"
DAT Alert - $Severity

Host: $hostname
Timestamp: $timestamp

$Message

This alert was generated by DAT (dag's Audit Tool).
"@
                SmtpServer  = $emailConfig.smtpServer
                Port        = $port
                UseSsl      = $useSsl
            }
            if ($Attachments -and @($Attachments).Count -gt 0) {
                $emailParams.Attachments = $Attachments
            }
            if ($credential) {
                $emailParams.Credential = $credential
            }

            Send-MailMessage @emailParams -ErrorAction Stop
            Write-Host "Alert sent via Email (from $fromAddress via $($emailConfig.smtpServer):$port, SSL=$useSsl)"
        }
        catch {
            # Surface the real SMTP error to the caller (the GUI Test button)
            # instead of a silent Write-Error that reports false success.
            throw "Email alert failed via $($emailConfig.smtpServer): $($_.Exception.Message)"
        }
    }

    # Webhook alerts (Slack, Teams, Discord, Custom)
    if ($Channels -contains "Webhook" -and $Config -and $Config.alerting.webhook.url) {
        try {
            $webhookConfig = $Config.alerting.webhook
            $webhookUrl = $webhookConfig.url
            
            # Detect webhook type and format payload accordingly
            $payload = $null
            
            # DAT skull mark - attached to Discord embeds as the thumbnail
            $script:DatLogoFile = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Assets\dat_logo_small.png"
            $logoAvailable = Test-Path $script:DatLogoFile

            if ($webhookUrl -match "discord\.com") {
                # Discord webhook format - Reaper theme colors
                $embedColor = switch ($Severity) {
                    "Critical" { 11149350 }  # Blood red (#AA2026)
                    "Warning" { 9736844 }    # Dim bone (#94928C)
                    default { 15526370 }     # Bone white (#ECE9E2)
                }

                # Truncate message to 4000 chars to be safe (limit is 4096)
                $safeMessage = if ($Message.Length -gt 4000) { $Message.Substring(0, 4000) + "... (truncated)" } else { $Message }

                $embed = @{
                    title       = "DAT Alert - $Severity"
                    description = $safeMessage
                    color       = $embedColor
                    fields      = @(
                        @{
                            name   = "Host"
                            value  = $hostname
                            inline = $true
                        },
                        @{
                            name   = "Severity"
                            value  = $Severity
                            inline = $true
                        },
                        @{
                            name   = "Timestamp"
                            value  = $timestamp
                            inline = $true
                        }
                    )
                    footer      = @{
                        text = "DAT - dag's Audit Tool"
                    }
                    timestamp   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                }
                if ($logoAvailable) {
                    $embed.thumbnail = @{ url = "attachment://dat_logo_small.png" }
                }

                $payload = @{
                    username   = "DAT - dag's Audit Tool"
                    avatar_url = "https://raw.githubusercontent.com/dagnazty/DAT/main/Assets/dat_logo_small.png"
                    embeds     = @($embed)
                } | ConvertTo-Json -Depth 10

            }
            elseif ($webhookUrl -match "slack\.com") {
                # Slack webhook format
                $payload = @{
                    text        = "DAT Alert - $Severity"
                    attachments = @(
                        @{
                            color  = switch ($Severity) {
                                "Critical" { "#AA2026" }  # Blood red
                                "Warning" { "#94928C" }   # Dim bone
                                default { "#ECE9E2" }     # Bone white
                            }
                            fields = @(
                                @{
                                    title = "Subject"
                                    value = $Subject
                                    short = $true
                                },
                                @{
                                    title = "Host"
                                    value = $hostname
                                    short = $true
                                },
                                @{
                                    title = "Timestamp"
                                    value = $timestamp
                                    short = $true
                                }
                            )
                            text   = $Message
                        }
                    )
                } | ConvertTo-Json -Depth 4
                
            }
            elseif ($webhookUrl -match "office\.com|outlook\.com") {
                # Microsoft Teams webhook format
                $themeColor = switch ($Severity) {
                    "Critical" { "AA2026" }  # Blood red
                    "Warning" { "94928C" }   # Dim bone
                    default { "ECE9E2" }     # Bone white
                }
                
                $payload = @{
                    "@type"    = "MessageCard"
                    "@context" = "https://schema.org/extensions"
                    summary    = "DAT Alert - $Severity"
                    themeColor = $themeColor
                    title      = "DAT Alert - $Severity"
                    sections   = @(
                        @{
                            activityTitle    = $Subject
                            activitySubtitle = $timestamp
                            facts            = @(
                                @{
                                    name  = "Host"
                                    value = $hostname
                                },
                                @{
                                    name  = "Severity"
                                    value = $Severity
                                },
                                @{
                                    name  = "Message"
                                    value = $Message
                                }
                            )
                        }
                    )
                } | ConvertTo-Json -Depth 4
                
            }
            else {
                # Generic webhook format
                $payload = @{
                    subject   = $Subject
                    message   = $Message
                    severity  = $Severity
                    host      = $hostname
                    timestamp = $timestamp
                } | ConvertTo-Json -Depth 4
            }

            $method = if ($webhookConfig.method) { $webhookConfig.method } else { "Post" }
            
            # Debug logging for webhook payload
            Write-Host "DEBUG: Webhook Payload: $payload"
            
            # Force UTF-8 encoding for the payload to handle emojis correctly
            # Force UTF-8 encoding for the payload to handle emojis correctly
            $utf8Payload = [System.Text.Encoding]::UTF8.GetBytes($payload)
            
            if (($Attachments -or $logoAvailable) -and $webhookUrl -match "discord\.com") {
                # Use HttpClient for multipart/form-data upload to Discord
                try {
                    Add-Type -AssemblyName System.Net.Http
                    $httpClient = New-Object System.Net.Http.HttpClient
                    $content = New-Object System.Net.Http.MultipartFormDataContent

                    # Add JSON payload
                    $jsonContent = New-Object System.Net.Http.ByteArrayContent(, $utf8Payload)
                    $jsonContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/json")
                    $content.Add($jsonContent, "payload_json")

                    # Add Files - the skull mark first, so the embed thumbnail
                    # (attachment://dat_logo_small.png) resolves
                    $fileIndex = 0
                    $filesToSend = @()
                    if ($logoAvailable) { $filesToSend += $script:DatLogoFile }
                    $filesToSend += $Attachments
                    foreach ($file in $filesToSend) {
                        if ($file -and (Test-Path $file)) {
                            $fileBytes = [System.IO.File]::ReadAllBytes($file)
                            $fileContent = New-Object System.Net.Http.ByteArrayContent(, $fileBytes)
                            $fileName = Split-Path $file -Leaf
                            $content.Add($fileContent, "files[$fileIndex]", $fileName)
                            $fileIndex++
                        }
                    }
                    
                    $response = $httpClient.PostAsync($webhookUrl, $content).Result
                    if (-not $response.IsSuccessStatusCode) {
                        throw "Discord upload failed: $($response.StatusCode)"
                    }
                    Write-Host "Alert sent via Webhook (with attachments)"
                }
                catch {
                    Write-Error "Failed to send webhook with attachments: $_"
                    # Fallback to normal send without attachments if upload fails
                    Invoke-RestMethod -Uri $webhookUrl -Method $method -Body $utf8Payload -ContentType "application/json; charset=utf-8"
                }
                finally {
                    if ($httpClient) { $httpClient.Dispose() }
                    if ($content) { $content.Dispose() }
                }
            }
            else {
                # Standard JSON payload for non-Discord or no-attachment calls
                Invoke-RestMethod -Uri $webhookUrl -Method $method -Body $utf8Payload -ContentType "application/json; charset=utf-8"
                Write-Host "Alert sent via Webhook"
            }
        }
        catch {
            Write-Error "Failed to send webhook alert: $_"
        }
    }
}

function Test-AlertSystem {
    param (
        [PSCustomObject]$Config = $null
    )
    
    # Load configuration if not provided
    if ($null -eq $Config) {
        try {
            if (Get-Command -Name Get-Configuration -ErrorAction SilentlyContinue) {
                $Config = Get-Configuration
            }
        }
        catch {
            # Configuration not available
        }
    }

    Write-Host "Testing alert system..."

    # Test Event Log
    Send-Alert -Subject "Test Alert" -Message "This is a test alert from DAT" -Channels "EventLog" -Severity "Info"

    # Test Email if configured
    if ($Config -and $Config.alerting.enabled -and $Config.alerting.email) {
        Send-Alert -Subject "Test Email Alert" -Message "This is a test email alert from DAT" -Channels "Email" -Severity "Info" -Config $Config
    }

    # Test Webhook if configured
    if ($Config -and $Config.alerting.enabled -and $Config.alerting.webhook.url) {
        Send-Alert -Subject "Test Webhook Alert" -Message "This is a test webhook alert from DAT" -Channels "Webhook" -Severity "Info" -Config $Config
    }

    Write-Host "Alert system test completed"
}

# Standalone execution example
# To test: .\Send-Alert.ps1
# Or: Send-Alert -Subject "Test" -Message "Test message" -Channels EventLog -Severity Info
