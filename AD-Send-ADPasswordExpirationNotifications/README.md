# Send-ADPasswordExpirationNotifications

Send an email notification to users whose password expires in X days.

# Variables

In the script, you can edit different variables :

$DateThreshold : Number of days before expiration to send the notification
$SMTPServer : SMTP server to send email notification
$SMTPPort : SMTP server port
$SMTPSender : Sender's email address
[boolean]$SendReportAdmin : true to send a summary to admin, or false to disable this functionality
$SendReportAdminEmail - Admin's email address (for the summary)

# Example

```
    .\Send-ADPasswordExpirationNotifications.ps1
```

# Notifications - Examples

- Example 1 - User notification

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/AD-Send-ADPasswordExpirationNotifications/Images/Send-ADPasswordExpirationNotifications-Notif1.png)

- Examples 2 - Admin notification (if enabled) - Summary

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/AD-Send-ADPasswordExpirationNotifications/Images/Send-ADPasswordExpirationNotifications-Notif2.png)