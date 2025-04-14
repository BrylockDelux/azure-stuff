# Entra ID Automations

## Overview
This project contains a PowerShell script that automates the process of adding users to a Microsoft Teams group based on a list of email addresses provided in a CSV file.

## Script Details
### Add-UsersToTeamsGroup.ps1
This script takes two parameters:
- **CSVFile**: The path to the CSV file containing user emails.
- **TeamsGroupId**: The identifier of the Teams group to which users will be added.

The script reads the CSV file, finds users by their email addresses, and adds them to the specified Teams group, supporting bulk operations.

## Sample Input
The `sample-users.csv` file serves as a sample input for the script. It should contain a list of user emails in a single column.

## Usage
To run the script, use the following command in PowerShell:

```powershell
.\Add-UsersToTeamsGroup.ps1 -CSVFile "path\to\your\sample-users.csv" -TeamsGroupId "your-teams-group-id"
```

Replace `"path\to\your\sample-users.csv"` with the actual path to your CSV file and `"your-teams-group-id"` with the actual Teams group identifier.

## Testing
The project includes unit tests located in the `tests` directory to ensure the functionality of the `Add-UsersToTeamsGroup.ps1` script works as expected.