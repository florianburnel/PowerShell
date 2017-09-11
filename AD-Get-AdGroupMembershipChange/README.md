# Get-AdGroupMembershipChange

This script queries multiple Active Directory groups for new members in a domain. It records group membership in a CSV file in the same location as the script is located. 
On the script's initial run it will simply record all members of all groups into this CSV file. 
On subsequent runs it will query each group's member list and compare that list to what's in the CSV file.
If any differences are found (added or removed) the script will update the CSV file to reflect current memberships and notify an administrator of which members were either added or removed.

# Example

```
        PS> .\Get-AdGroupMembershipChange.ps1 -Email "florian.burnel@mydomain.fr" -LogFilePath "C:\Logs\Audit_Get-AdGroupMembershipChange\Audit_log.csv" -GroupFilePath "C:\Logs\Audit_Get-AdGroupMembershipChange\Audit_list_reference.csv" -Group "Administrateurs de l’entreprise", "Admins du domaine"
```

- Group : One or more group names to monitor for membership changes

- Email : The email address of the administrator that would like to get notified of group changes. The notification contain an HTML report.

- LogFilePath : This file logs the different actions in monitored groups

- GroupFilePath : This is the file that will record the most recent group membership and will be used to compare current to most recent. It's the reference file.

- SendByEmail : Boolean, if it's true notification will be send by email, otherwise the result will be only export in HTML or display in the console (it depends on ExportAsHTML)

- ExportAsHTML : Path to the file for the html report

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/AD-Get-AdGroupMembershipChange/Images/Get-AdGroupMembershipChange_1.png)

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/AD-Get-AdGroupMembershipChange/Images/Get-AdGroupMembershipChange_2.png)