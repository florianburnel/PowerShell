# Invoke-JeedomBackup

Jeedom can generate is own backup. With this script, you can copy Jeedom backup to an external storage, such as a NAS.
The retention policy on the external storage can be define in a variable (DeleteBackupOlderThanXDays). 
Warning : This script is compatible with PowerShell Core on Linux system.
This script is provided AS IS

# Example

```
         PS> ./Invoke-JeedomBackup.ps1 -BackupSrc "/var/www/html/backup" -BackupDest "/mnt/backup" -MountTarget "//192.168.1.150/Sauvegardes/Jeedom" -CredsFile "/root/.backupcreds" -DeleteBackupOlderThanXDays 30

```

- BackupSrc : The source folder where Jeedom backups are stored
        
- BackupDest : The mount point used to mount the external storage (share)
        
- MountTarget : The path to the share on the external storage
        
- CredsFile : For security reason, credentials are stored in a un specific file, indicate the path to this file
        
- DeleteBackupOlderThanXDays : Retention policy, delete backup older than X days

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/LINUX-Invoke-JeedomBackup/Images/LINUX-Invoke-JeedomBackup.png)