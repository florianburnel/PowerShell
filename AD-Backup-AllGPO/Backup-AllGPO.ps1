<#
.SYNOPSIS
	This script backup all the GPO of your domain Active Directory in a backup folder.

.DESCRIPTION
	This script backup all the GPO of your domain Active Directory in a backup folder with a different subfolder for each backup. 
    You can also specify a number of backups to keep in the principal backup folder, it's important if you want to execute this script in a schedule task.

.PARAMETER Destination
    The path to the root folder for store the backups, a subfolder "<domain-name>_<date>" will be created in this folder for the backup
    Please, don't indicate the "slash" at the end of the path

.PARAMETER BackupToKeep
    Number of backups to keep in the root folder define in the parameter "Destination".

.EXAMPLE
    .\Backup-AllGPO.ps1 -Destination "V:\Sauvegardes\GPO"
    Backup all the GPO in a subfolder of "V:\Sauvegardes\GPO". No retention management

    .\Backup-AllGPO.ps1 -Destination "V:\Sauvegardes\GPO" -BackupToKeep 31
    Backup all the GPO in a subfolder of "V:\Sauvegardes\GPO" and it keep 31 backups in the root folder, after the 32nd backup the older will be delete for keep 31 backups.

    powershell.exe -Command "& C:\Scripts\Backup-AllGPO.ps1 -Destination '\\Server\Sauvegarde\GPO' -BackupToKeep 31"
    Example of syntax if you want to execute this script in a schedule task.

.INPUTS

.OUTPUTS
	
.NOTES
	NAME:	Backup-AllGPO.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel

	REQUIREMENTS:
		- Module PowerShell "Active Directory"
        - Module PowerShell "GroupPolicy"

	VERSION HISTORY:

	1.0 	2016.11.22
		    Initial Version

    TODO
            Add notifications when the backup is incomplete
#>

PARAM(
    [Parameter(Mandatory = $true, HelpMessage = "You must specify a destination path to store backups")]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    $Destination,

    [int]$BackupToKeep
)

# Import module
Import-Module ActiveDirectory -ErrorAction SilentlyContinue -ErrorVariable ErrorImportModule
Import-Module GroupPolicy -ErrorAction SilentlyContinue -ErrorVariable +ErrorImportModule

if($ErrorImportModule){

    Write-Host "WARNING : Something went wront during the module importation" -ForegroundColor DarkYellow

}else{

    # Create a subfolder "domain.local_yyyyMMdd" in the destination path
    $DateOfTheDay = Get-Date -Format "yyyyMMdd"
    $DomainName = (Get-ADDomain).DNSRoot
    $DestinationFullPath = $Destination + "\" + $DomainName + "_" + $DateOfTheDay

    # Create the destination folder, if not exist
    if(!(Test-Path $DestinationFullPath)){

        Write-Host "Destination folder will be create : $DestinationFullPath" -ForegroundColor Green
        New-Item -Path $DestinationFullPath -ItemType Directory -ErrorAction SilentlyContinue -ErrorVariable ErrorNewItem
        
    } # if(!(Test-Path $DestinationFullPath))

    # If the destination folder is OK, backup all the GPO into this folder
    if($ErrorNewItem){

        Write-Host "WARNING : The creation of the destination folder failed !" -ForegroundColor DarkYellow    
    
    }else{

        Get-GPO -Domain $DomainName -All | Backup-GPO -Path $DestinationFullPath

    } # if($ErrorNewItem)

    # Compare the number of GPO with the number of subfolder in the destination path
    if((Get-ChildItem -Path $DestinationFullPath -Exclude "GPOStarter").Count -eq (Get-GPO -Domain $DomainName -All).Count){

        Write-Host "GPO - Backup complete : " $(Get-ChildItem -Path $DestinationFullPath).Count "/" $(Get-GPO -Domain $DomainName -All).Count -ForegroundColor Green

        # Backup is complete, we can delete older backup if it necessary (it depends of the number of backup to keep VS the number of actual backup)
        $BackupTotal = (Get-ChildItem -Path $Destination).Count

        if($BackupTotal -gt $BackupToKeep){

            Write-Host "There are more than $BackupToKeep backup(s) in the backup folder !" -ForegroundColor Yellow

            # Calculate the number of backups to delete
            $BackupToDelete = $BackupTotal - $BackupToKeep

            Write-Host "There are $BackupToDelete backup(s) to delete" -ForegroundColor Yellow

            # Identify older backups and delete them
            Get-ChildItem -Path $Destination | Select Name -First $BackupToDelete | foreach{ Remove-Item -Path "$Destination\$($_.Name)" -Recurse -Force }

        }else{

            Write-Host "No needs to delete some backups for the moment" -ForegroundColor Green

        } # if($BackupTotal -gt $BackupToKeep)

    }else{

        Write-Host "WARNING : GPO - Backup incomplete : " $(Get-ChildItem -Path $DestinationFullPath -Exclude "GPOStarter").Count "/" $(Get-GPO -Domain $DomainName -All).Count -ForegroundColor DarkYellow

    } # if((Get-ChildItem -Path $DestinationFullPath).Count -eq (Get-GPO -Domain $DomainName -All).Count)

} # if($ErrorImportModule)