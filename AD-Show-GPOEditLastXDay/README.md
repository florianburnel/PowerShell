# Show-GPOEditLastXDay

What are the GPOs modified in the last X days ? The script detects which GPOs are modified in the last X days, based on the current date at the execution time

# Example

```
    .\Show-GPOEditLastXDay.ps1 -DomainName "it-connect.local" -LastXDays 7
```

- DomainName : This parameter must contain the DNS name of your domain Active Directory (Example : it-connect.local)

- LastXDays : Number of days to consider for detect a change in one of the GPO (Example : 7 (for 7 days))

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/AD-Show-GPOEditLastXDay/Images/Show-GPOEditLastXDay-example.png)