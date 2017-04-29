# New-TeamsMessage

This script publish a message in a Microsoft Teams chanel where a connector "Incoming Webhook" is configure.

First, you must add a connector "Incoming Webhook" to your Microsoft Teams chanel and copy the URL of this webhook. After, using this script you can send a message directly in Microsoft Teams with PowerShell
With this, you can imagine many use case ! For my script, I have used the original snippet of Stefan Stranger ("Call Microsoft Teams Incoming Webhook from PowerShell")

# Examples

```
    .\New-TeamsMessage.ps1 -WebhookURL "https://outlook.office.com/webhook/a9999b3f-1001-4711-f4h9-5e6fffggggg@aaaaa-bbbbb-cccccc/IncomingWebhook/28g90bdcb7ad312ab7afe6598ca7f69b/4a10bd21-2017-fbfb-ffff-585f639e84b0" -MessageText "My message" -MessageTitle "My title" -MessageColor "00FFFF"
```

- WebhookURL : The URL of your Webhook, it must be match with "https://outlook.office.com/webhook/"

- MessageText : The body of your message to publish on Teams

- MessageTitle : The title of your message

- MessageColor : The color theme for your message

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/O365-New-TeamsMessage/Images/New-TeamsMessage-1.png)


An other example, a message without title :

```
	.\New-TeamsMessage.ps1 -WebhookURL "https://outlook.office.com/webhook/a9999b3f-1001-4711-f4h9-5e6fffggggg@aaaaa-bbbbb-cccccc/IncomingWebhook/28g90bdcb7ad312ab7afe6598ca7f69b/4a10bd21-2017-fbfb-ffff-585f639e84b0" -MessageText "My message, without title" -MessageColor "FF0000"
```

The result in Microsoft Teams :

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/O365-New-TeamsMessage/Images/New-TeamsMessage-2.png)


Finally, a third example, a message with a link and a title :

```
    .\New-TeamsMessage.ps1 -WebhookURL "https://outlook.office.com/webhook/a9999b3f-1001-4711-f4h9-5e6fffggggg@aaaaa-bbbbb-cccccc/IncomingWebhook/28g90bdcb7ad312ab7afe6598ca7f69b/4a10bd21-2017-fbfb-ffff-585f639e84b0" -MessageText "Visit my website : [it-connect.fr](https://www.it-connect.fr)" -MessageTitle "IT-Connect" -MessageColor "FF6600"
```

The result in Microsoft Teams :

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/O365-New-TeamsMessage/Images/New-TeamsMessage-3.png)