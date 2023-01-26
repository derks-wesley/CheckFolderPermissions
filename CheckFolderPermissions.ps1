<#
.SYNOPSIS
    This script allows you to check permission on any folder you want and automaticly exports it to an .CSV file. 

.DESCRIPTION
    This script allows you to check permission on any folder you want using a GUI Dialog Box.
    By default some Windows Sytstem users are excluded from the export since these are inrealevant most of the time. You can add/change these users simply by adding it to $excludeUsers. If you want to disable it just add the # before it.
    Run this script as a administrator, otherwise it will not run properly due to checking the security attributes of a folder.

.EXAMPLE
    Example syntax for running the script or function.
    PS C:\> CheckFolderPermissions.ps1 (make sure the file is located on the location you run it from)

.NOTES
    Filename: CheckFolderPermissions.ps1
    Author: Wesley Derks
    Modified date: 2023/01/25
    Version 1.0 - First release.
#>

# Create a folder picker dialog box
$folderDialog = New-Object -ComObject Shell.Application
$folder = $folderDialog.BrowseForFolder(0, "Select a folder", 0, 0)

# Get the full path of the selected folder
$path = $folder.Self.Path

# Enumerate all subfolders
$folders = Get-ChildItem -Path $path -Directory

# Define the path and file name for the CSV file
$csvPath = "C:\folder_access_rights.csv"

# Delete the CSV file if it already exists
Remove-Item $csvPath -ErrorAction SilentlyContinue

# Define the users to exclude
$excludeUsers = "BUILTIN\Administrators", "NT AUTHORITY\SYSTEM", "CREATOR OWNER"

# Loop through each folder
foreach ($folder in $folders) {
    # Get the security descriptor for the folder
    $acl = Get-Acl -Path $folder.FullName

    # Loop through each access rule
    foreach ($rule in $acl.Access) {
        # Check if the user is in the exclude list
        if ($excludeUsers -notcontains $rule.IdentityReference) {
            # Create an object for the output
            $output = New-Object PSObject -Property @{
                FolderPath = $folder.FullName
                Identity = $rule.IdentityReference
                AccessRights = $rule.FileSystemRights
            }

            # Add the output to the CSV file
            $output | Export-Csv -Path $csvPath -Append -NoTypeInformation
        }
    }
    # Look one folder deeper
    $subfolders = Get-ChildItem -Path $folder.FullName -Directory
    foreach ($subfolder in $subfolders) {
        # Get the security descriptor for the subfolder
        $subfolderAcl = Get-Acl -Path $subfolder.FullName

        # Loop through each access rule
        foreach ($subfolderRule in $subfolderAcl.Access) {
            # Check if the user is in the exclude list
            if ($excludeUsers -notcontains $subfolderRule.IdentityReference) {
                # Create an object for the output
                $output = New-Object PSObject -Property @{
                    FolderPath = $subfolder.FullName
                    Identity = $subfolderRule.IdentityReference
                    AccessRights = $subfolderRule.FileSystemRights
                }

                # Add the output to the CSV file
                $output | Export-Csv -Path $csvPath -Append -NoTypeInformation
            }
        }
    }
}
