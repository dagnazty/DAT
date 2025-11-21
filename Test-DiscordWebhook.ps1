# Test Discord Webhook
# Quick script to test your Discord webhook configuration

param(
    [Parameter(Mandatory=$false)]
    [string]$WebhookUrl = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Discord Webhook Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get webhook URL
if (-not $WebhookUrl) {
    Write-Host "Enter your Discord webhook URL:" -ForegroundColor Yellow
    Write-Host "(Format: https://discord.com/api/webhooks/ID/TOKEN)" -ForegroundColor Gray
    $WebhookUrl = Read-Host "Webhook URL"
}

if (-not $WebhookUrl) {
    Write-Host "No webhook URL provided. Exiting." -ForegroundColor Red
    exit 1
}

# Validate URL
if ($WebhookUrl -notmatch "discord\.com") {
    Write-Host "WARNING: URL doesn't look like a Discord webhook" -ForegroundColor Yellow
    Write-Host "Expected format: https://discord.com/api/webhooks/..." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Testing webhook..." -ForegroundColor Yellow
Write-Host "URL: $($WebhookUrl.Substring(0, [Math]::Min(50, $WebhookUrl.Length)))..." -ForegroundColor Gray
Write-Host ""

# Test 1: Simple message
Write-Host "[1/4] Sending simple text message..." -ForegroundColor Cyan
try {
    $simplePayload = @{
        content = "✅ Test message from DAT - Simple format"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $simplePayload -ContentType 'application/json'
    Write-Host "  ✅ Simple message sent!" -ForegroundColor Green
    Start-Sleep -Seconds 2
} catch {
    Write-Host "  ❌ Failed: $_" -ForegroundColor Red
}

# Test 2: Info alert (Blue)
Write-Host "[2/4] Sending INFO alert (Blue)..." -ForegroundColor Cyan
try {
    $infoPayload = @{
        username = "DAT Audit Tool"
        embeds = @(
            @{
                title = "🔔 DAT Alert - Info"
                description = "**Test Info Alert**"
                color = 3066993  # Blue
                fields = @(
                    @{
                        name = "Message"
                        value = "This is a test INFO alert from DAT"
                        inline = $false
                    },
                    @{
                        name = "Host"
                        value = $env:COMPUTERNAME
                        inline = $true
                    },
                    @{
                        name = "Severity"
                        value = "Info"
                        inline = $true
                    }
                )
                footer = @{
                    text = "DAT - Desktop Audit Tool"
                }
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $infoPayload -ContentType 'application/json'
    Write-Host "  ✅ Info alert sent!" -ForegroundColor Green
    Start-Sleep -Seconds 2
} catch {
    Write-Host "  ❌ Failed: $_" -ForegroundColor Red
}

# Test 3: Warning alert (Yellow)
Write-Host "[3/4] Sending WARNING alert (Yellow)..." -ForegroundColor Cyan
try {
    $warningPayload = @{
        username = "DAT Audit Tool"
        embeds = @(
            @{
                title = "⚠️ DAT Alert - Warning"
                description = "**Test Warning Alert**"
                color = 16776960  # Yellow
                fields = @(
                    @{
                        name = "Message"
                        value = "This is a test WARNING alert from DAT"
                        inline = $false
                    },
                    @{
                        name = "Host"
                        value = $env:COMPUTERNAME
                        inline = $true
                    },
                    @{
                        name = "Severity"
                        value = "Warning"
                        inline = $true
                    }
                )
                footer = @{
                    text = "DAT - Desktop Audit Tool"
                }
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $warningPayload -ContentType 'application/json'
    Write-Host "  ✅ Warning alert sent!" -ForegroundColor Green
    Start-Sleep -Seconds 2
} catch {
    Write-Host "  ❌ Failed: $_" -ForegroundColor Red
}

# Test 4: Critical alert (Red)
Write-Host "[4/4] Sending CRITICAL alert (Red)..." -ForegroundColor Cyan
try {
    $criticalPayload = @{
        username = "DAT Audit Tool"
        embeds = @(
            @{
                title = "🚨 DAT Alert - Critical"
                description = "**Test Critical Alert**"
                color = 15158332  # Red
                fields = @(
                    @{
                        name = "Message"
                        value = "This is a test CRITICAL alert from DAT"
                        inline = $false
                    },
                    @{
                        name = "Host"
                        value = $env:COMPUTERNAME
                        inline = $true
                    },
                    @{
                        name = "Severity"
                        value = "Critical"
                        inline = $true
                    }
                )
                footer = @{
                    text = "DAT - Desktop Audit Tool"
                }
                timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
            }
        )
    } | ConvertTo-Json -Depth 10
    
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $criticalPayload -ContentType 'application/json'
    Write-Host "  ✅ Critical alert sent!" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check your Discord channel to see the messages!" -ForegroundColor Yellow
Write-Host ""
Write-Host "You should see:" -ForegroundColor Cyan
Write-Host "  1. Simple text message" -ForegroundColor Gray
Write-Host "  2. Blue embedded message (Info)" -ForegroundColor Gray
Write-Host "  3. Yellow embedded message (Warning)" -ForegroundColor Gray
Write-Host "  4. Red embedded message (Critical)" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Add webhook URL to DAT Settings (GUI)" -ForegroundColor Gray
Write-Host "  2. Or edit Config\DefaultConfig.json" -ForegroundColor Gray
Write-Host "  3. Click 'Test Alert' in Settings tab" -ForegroundColor Gray
Write-Host ""
