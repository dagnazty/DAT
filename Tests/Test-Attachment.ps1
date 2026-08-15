# Test script for File Attachment Verification

# Load necessary functions
. "$PSScriptRoot\..\Functions\Send-Alert.ps1"

# Mock Config
$script:config = @{
    alerting = @{
        enabled = $true
        webhook = @{
            url = "https://discord.com/api/webhooks/1234567890" # Fake URL
            method = "Post"
        }
    }
}

# Create dummy attachment
$attachmentPath = "$env:TEMP\Test_Attachment.txt"
"This is a test attachment content.`nGenerated at $(Get-Date)" | Set-Content -Path $attachmentPath

Write-Host "Testing Webhook Alert with Attachment..."

try {
    Send-Alert -Subject "Test Attachment" -Message "Sending a file..." -Channels "Webhook" -Severity "Info" -Config $script:config -Attachments @($attachmentPath)
} catch {
    Write-Host "Caught expected error (due to fake URL): $_"
} finally {
    if (Test-Path $attachmentPath) {
        Remove-Item $attachmentPath
    }
}
