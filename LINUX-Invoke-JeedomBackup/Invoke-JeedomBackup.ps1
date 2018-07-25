<#
        .SYNOPSIS
        
         Jeedom can generate is own backup. With this script, you can copy Jeedom backup to an external storage, such as a NAS.
         The retention policy on the external storage can be define in a variable (DeleteBackupOlderThanXDays). 
         Warning : This script is compatible with PowerShell Core on Linux system.
        
        .NOTES
	     NAME:	Invoke-JeedomBackup.ps1
	     AUTHOR:	Florian Burnel
	     EMAIL:	florian.burnel@it-connect.fr
         URL : www.it-connect.fr
	     TWITTER: @FlorianBurnel
        
        .EXAMPLE        
         PS> ./Invoke-JeedomBackup.ps1 -BackupSrc "/var/www/html/backup" -BackupDest "/mnt/backup" -MountTarget "//192.168.1.150/Sauvegardes/Jeedom" -CredsFile "/root/.backupcreds" -DeleteBackupOlderThanXDays 30
   
        .PARAMETER BackupSrc
         The source folder where Jeedom backups are stored
        
        .PARAMETER BackupDest
         The mount point used to mount the external storage (share)
        
        .PARAMETER MountTarget
         The path to the share on the external storage
        
        .PARAMETER CredsFile
         For security reason, credentials are stored in a un specific file, indicate the path to this file
        
        .PARAMETER DeleteBackupOlderThanXDays
         Retention policy, delete backup older than X days
        
	    VERSION HISTORY:
	        
        1.0.0 	2018.07.11
	            Initial Version
#>

param (

    [string][ValidateScript({Test-Path $_ })]$BackupSrc = "/var/www/html/backup",
    [Parameter(Mandatory)][string]$BackupDest,
    [Parameter(Mandatory)][string]$MountTarget,
    [Parameter(Mandatory)][string][ValidateScript({Test-Path $_ })]$CredsFile,
    [int]$DeleteBackupOlderThanXDays = 30
)

# Do not edit this variable
$ReferenceDate = (Get-Date).AddDays(-$DeleteBackupOlderThanXDays)

# Backup destination - Mount the network drive
mount.cifs $MountTarget $BackupDest -o credentials=$CredsFile

# Before continue check if the "mount.file" is available
if(Test-Path "$BackupDest/mount.file"){

  # Copy the last backup to $BackupDest
  Get-ChildItem -Path $BackupSrc/* -Include backup-*.tar.gz `
        | Sort-Object CreationTime `
        | Select-Object -Last 1 `
        | Copy-Item -Destination $BackupDest -ErrorAction SilentlyContinue -ErrorVariable ErrorCopy

  # Check the result of the copy
  if(!($ErrorCopy)){

    Write-Output "Copy state : Successful to $BackupDest - $MountTarget !"
  
  }else{
  
    Write-Output "Copy state : Error ! $ErrorCopy"
  
  } # if(!($ErrorCopy))

  # Delete older backups
  Get-ChildItem $BackupDest/* -Include backup-*.tar.gz | Select-Object Name,CreationTime | ForEach-Object{

     $ItemCreationTime = $_.CreationTime
  
     if($ReferenceDate -gt $ItemCreationTime){

        Write-Output "The file <$($_.Name)> is older than $DeleteBackupOlderThanXDays days"
		Remove-Item -Path "$($_.Fullname)" -Force -Confirm:$false

     } # if($ReferenceDate -gt $ItemCreationTime)
  }

  # Backup destination - Umount the network drive
  umount $BackupDest

}else {

  Write-Output "Error ! The network drive is not mounting correctly in $BackupDest (test file mount.file not found)"

} # if(Test-Path "$BackupDest/mount.file")

