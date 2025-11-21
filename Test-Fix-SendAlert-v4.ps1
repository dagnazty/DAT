# Test script for Emoji Removal Verification

# Load the function
. "$PSScriptRoot\Functions\Send-Alert.ps1"

# Mock Config
$mockConfig = @{
    alerting = @{
        enabled = $true
        webhook = @{
            url = "https://discord.com/api/webhooks/1234567890"
            method = "Post"
        }
    }
}

Write-Host "Testing Webhook Alert for Emojis..."
try {
    # We expect Invoke-RestMethod to fail, but we want to see the debug JSON output
    Send-Alert -Subject "Test Clean Alert" -Message "Testing Emoji Removal" -Channels "Webhook" -Config $mockConfig
} catch {
    Write-Host "Caught expected error: $_"
}
