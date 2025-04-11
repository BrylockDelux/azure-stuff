function Get-BearerToken {
    param (
        [string]$ClientId,
        [string]$Scope,
        [string]$TenantId = "common",
        [string]$ClientSecret = "",
        [switch]$UseClientSecret
    )

    if ($UseClientSecret) {
        if ([string]::IsNullOrEmpty($ClientSecret)) {
            Write-Host "❌ Client Secret is required when using client ID authentication"
            exit 1
        }

        # Client Credentials Flow
        $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        
        $tokenResponse = curl -sS -X POST $tokenUrl `
             -H "Content-Type: application/x-www-form-urlencoded" `
             --data "client_id=$ClientId&scope=$Scope&client_secret=$ClientSecret&grant_type=client_credentials"

        # Convert JSON response to a PowerShell object
        $tokenJson = $tokenResponse | ConvertFrom-Json

        if (-not $tokenJson.access_token) {
            Write-Host "❌ Failed to retrieve access token. Exiting..."
            exit 1
        }

        Write-Host "✅ Access Token Acquired!"
        return @{
            AccessToken = $tokenJson.access_token
        }
    }
    else {
        # Interactive Authentication Flow
        # Define multiple ports to check for availability
        $portsToTry = @(8000, 8080, 5000, 3000)
        $redirectUri = $null
        $listener = $null

        # Try available ports
        foreach ($port in $portsToTry) {
            try {
                $listener = New-Object System.Net.HttpListener
                $listener.Prefixes.Add("http://localhost:$port/")
                $listener.Start()
                $redirectUri = "http://localhost:$port"
                Write-Host "✅ Using available port: $port"
                break
            } catch {
                Write-Host "⚠️ Port $port is already in use. Trying another..."
            }
        }

        if (-not $redirectUri) {
            Write-Host "❌ No available ports found! Exiting..."
            exit 1
        }

        # URL encode the parameters
        $encodedRedirectUri = [System.Web.HttpUtility]::UrlEncode($redirectUri)
        $encodedScope = [System.Web.HttpUtility]::UrlEncode("$Scope")

        # Generate the OAuth URL with offline_access scope for refresh token
        $authUrl = "https://login.microsoftonline.com/$($TenantId.Trim())/oauth2/v2.0/authorize?client_id=$ClientId&response_type=code&redirect_uri=$encodedRedirectUri&scope=$encodedScope&response_mode=query"

        # Open Browser for Login
        Write-Host "Opening browser for authentication..."
        Start-Process $authUrl

        # Wait for user login and capture the authorization code
        $context = $listener.GetContext()
        $authCode = $context.Request.Url.Query -replace "^.*code=([^&]+).*$", '$1'

        # Respond to the browser
        $responseString = "<html><body><h2>Authentication successful! You may close this window.</h2></body></html>"
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
        $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
        $context.Response.Close()

        # Stop the listener
        $listener.Stop()
        Write-Host "✅ Authorization Code Captured"

        # Exchange Authorization Code for Bearer Token
        $tokenUrl = "https://login.microsoftonline.com/$($TenantId.Trim())/oauth2/v2.0/token"

        $tokenResponse = curl -sS -X POST $tokenUrl `
             -H "Content-Type: application/x-www-form-urlencoded" `
             --data "client_id=$ClientId&grant_type=authorization_code&code=$authCode&redirect_uri=$encodedRedirectUri&scope=$encodedScope"

        # Convert JSON response to a PowerShell object
        $tokenJson = $tokenResponse | ConvertFrom-Json

        if (-not $tokenJson.access_token) {
            Write-Host "❌ Failed to retrieve access token. Response: $tokenResponse"
            exit 1
        }

        Write-Host "✅ Access Token Acquired!"
        return @{
            AccessToken = $tokenJson.access_token
            RefreshToken = $tokenJson.refresh_token
        }
    }
}
