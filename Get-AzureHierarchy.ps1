# Script to generate Azure Management Groups and Subscriptions hierarchy in Mermaid format
# Requires Azure PowerShell module and Azure AD authentication

param (
    [string]$TenantId = "common",  # Default to "common" for multi-tenant access
    [switch]$UseClientSecret,
    [string]$ClientId,
    [string]$ClientSecret
)

# Import the token acquisition function
. .\Get-AuthToken.ps1

# Function to get all management groups recursively
function Get-ManagementGroupHierarchy {
    param (
        [string]$GroupId,
        [string]$ParentId = "",
        [string]$AccessToken
    )
    
    $headers = @{
        'Authorization' = "Bearer $AccessToken"
        'Content-Type' = 'application/json'
    }
    
    # Get management group details
    $mgUrl = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$GroupId`?api-version=2020-05-01"
    $mgResponse = Invoke-RestMethod -Uri $mgUrl -Headers $headers -Method Get
    $mg = $mgResponse
    
    $result = @()
    
    # Add current management group
    $result += @{
        Id = $mg.id
        Name = $mg.properties.displayName
        ParentId = $ParentId
        Type = "ManagementGroup"
    }
    
    # Get child management groups and subscriptions
    $childrenUrl = "https://management.azure.com/providers/Microsoft.Management/managementGroups/$GroupId/children`?api-version=2020-05-01"
    $childrenResponse = Invoke-RestMethod -Uri $childrenUrl -Headers $headers -Method Get
    
    foreach ($child in $childrenResponse.value) {
        if ($child.type -eq "Microsoft.Management/managementGroups") {
            $childId = $child.id.Split('/')[-1]
            $result += Get-ManagementGroupHierarchy -GroupId $childId -ParentId $mg.id -AccessToken $AccessToken
        }
        else {
            # Add subscription
            $result += @{
                Id = $child.id
                Name = $child.properties.displayName
                ParentId = $mg.id
                Type = "Subscription"
            }
        }
    }
    
    return $result
}

try {
    # Get the access token with explicit management group scope
    $scope = "Microsoft.Management/managementGroups/read"
    
    if ($UseClientSecret) {
        if ([string]::IsNullOrEmpty($ClientId)) {
            Write-Host "❌ Client ID is required when using client secret authentication"
            exit 1
        }
        Write-Host "Using client ID authentication..."
        $tokenInfo = Get-BearerToken -ClientId $ClientId -Scope $scope -TenantId $TenantId -ClientSecret $ClientSecret -UseClientSecret
    }
    else {
        Write-Host "Using interactive authentication..."
        if ([string]::IsNullOrEmpty($ClientId)) {
            $ClientId = "1950a258-227b-4e31-a9cf-717495945fc2"  # Default Azure PowerShell client ID
            Write-Host "Using default Azure PowerShell client ID"
        }
        Write-Host "Using tenant ID: $TenantId"
        Write-Host "Requesting scope: $scope"
        $tokenInfo = Get-BearerToken -ClientId $ClientId -Scope $scope -TenantId $TenantId
    }
    
    if (-not $tokenInfo.AccessToken) {
        Write-Host "❌ Failed to acquire access token. Exiting..."
        exit 1
    }
    
    Write-Host "✅ Successfully authenticated with Azure"
    
    # Get complete hierarchy
    $hierarchy = Get-ManagementGroupHierarchy -GroupId "root" -AccessToken $tokenInfo.AccessToken
    
    # Generate Mermaid diagram
    Write-Host "````mermaid"
    Write-Host "graph TD"
    
    # Add nodes
    foreach ($item in $hierarchy) {
        $nodeId = $item.Id.Replace("/", "_").Replace(":", "_")
        $nodeStyle = if ($item.Type -eq "ManagementGroup") { "((MG))" } else { "((Sub))" }
        Write-Host "    $nodeId[$item.Name]$nodeStyle"
    }
    
    # Add relationships
    foreach ($item in $hierarchy) {
        if ($item.ParentId) {
            $parentId = $item.ParentId.Replace("/", "_").Replace(":", "_")
            $nodeId = $item.Id.Replace("/", "_").Replace(":", "_")
            Write-Host "    $parentId --> $nodeId"
        }
    }
    
    Write-Host "````"
}
catch {
    Write-Host "Error: $_"
    Write-Host "Please ensure you have the necessary permissions and the Azure PowerShell module installed."
} 