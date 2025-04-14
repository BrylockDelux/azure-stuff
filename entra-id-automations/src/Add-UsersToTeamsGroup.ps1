[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,
    
    [Parameter(Mandatory = $true)]
    [string]$TeamIdentifier
)

# Import required module
Import-Module Microsoft.Graph.Teams
Import-Module Microsoft.Graph.Users
# Ensure necessary modules are installed
$requiredModules = @("Microsoft.Graph.Authentication")
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module module..."
        Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser
    }
}

# Import authentication module
Import-Module Microsoft.Graph.Authentication
# Connect to Microsoft Graph (make sure you're already authenticated)
try {
    $context = Get-MgContext
    if (-not $context) {
        Connect-MgGraph -Scopes "TeamMember.ReadWrite.All", "User.Read.All","Team.ReadBasic.All","Directory.Read.All","Group.Read.All","User.ReadBasic.All"
    }
}
catch {
    Write-Error "Failed to connect to Microsoft Graph. Please ensure you have the proper permissions."
    exit 1
}

# Import CSV file
try {
    $users = Import-Csv -Path $CsvPath
    if (-not $users) {
        Write-Error "No users found in the CSV file or file is empty."
        exit 1
    }
}
catch {
    Write-Error "Failed to import CSV file: $_"
    exit 1
}

# Get team ID if name was provided
try {
    if ($TeamIdentifier -notmatch '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
        $team = Get-MgTeam -Filter "displayName eq '$TeamIdentifier'"
        $teamId = $team.Id
    }
    else {
        $teamId = $TeamIdentifier
    }
}
catch {
    Write-Error "Failed to find team: $_"
    exit 1
}

# Process each user
foreach ($user in $users) {
    try {
        # Find user by email
        $mgUser = Get-MgUser -Filter "mail eq '$($user.userEmail)' or userPrincipalName eq '$($user.userEmail)'"
        
        if ($mgUser) {
            # Add user to team
            New-MgTeamMember -TeamId $teamId -DirectoryObjectId $mgUser.Id
            Write-Host "Successfully added $($user.userEmail) to the team"
        }
        else {
            Write-Warning "User not found: $($user.userEmail)"
        }
    }
    catch {
        Write-Error "Failed to process user $($user.userEmail): $_"
    }
}

Write-Host "Process completed."