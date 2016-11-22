# Backup-AllGPO

This script backup all the GPO of your domain Active Directory in a backup folder with a different subfolder for each backup. You can also specify a number of backups to keep in the principal backup folder, it's important if you want to execute this script in a schedule task.

# Example

```
    .\Backup-AllGPO.ps1 -Destination "V:\Sauvegardes\GPO"
```

Or

```
	.\Backup-AllGPO.ps1 -Destination "V:\Sauvegardes\GPO" -BackupToKeep 31
```

- Destination : The path to the root folder for store the backups, a subfolder "<domain-name>_<date>" will be created in this folder for the backup. Please, don't indicate the "slash" at the end of the path

- BackupToKeep : Number of backups to keep in the root folder define in the parameter "Destination".

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/AD-Backup-AllGPO/Images/Backup-AllGPO-Example.png)