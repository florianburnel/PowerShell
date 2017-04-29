<#
.SYNOPSIS
	Publish a message in a Microsoft Teams chanel where a connector "Incoming Webhook" is configure.

.DESCRIPTION
    First, you must add a connector "Incoming Webhook" to your Microsoft Teams chanel and copy the URL of this webhook
    After, using this script you can send a message directly in Microsoft Teams with PowerShell
    With this, you can imagine many use case !
    For my script, I have used the original snippet of Stefan Stranger ("Call Microsoft Teams Incoming Webhook from PowerShell")

.PARAMETER WebhookURL
    The URL of your Webhook, it must be match with "https://outlook.office.com/webhook/"

.PARAMETER MessageText
    The body of your message to publish on Teams

.PARAMETER MessageTitle
    The title of your message

.PARAMETER MessageColor
    The color theme for your message

.EXAMPLE
    .\New-TeamsMessage.ps1 -WebhookURL "https://outlook.office.com/webhook/a9999b3f-1001-4711-f4h9-5e6fffggggg@aaaaa-bbbbb-cccccc/IncomingWebhook/28g90bdcb7ad312ab7afe6598ca7f69b/4a10bd21-2017-fbfb-ffff-585f639e84b0" -MessageText "My message" -MessageTitle "My title" -MessageColor "339966"
    
.INPUTS

.OUTPUTS
	
.NOTES
	NAME:	New-TeamsMessage.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel

	VERSION HISTORY:

	1.0 	2017.04.29
		    Initial Version

#>
param(
    #[parameter(Mandatory=$true)][ValidatePattern("^https://outlook.office.com/webhook/*")][string]$WebhookURL,
    [parameter(Mandatory=$true)][string]$WebhookURL,
    [parameter(Mandatory=$true)][string]$MessageText,
    [parameter(Mandatory=$false)][string]$MessageTitle,
    [parameter(Mandatory=$false)][ValidatePattern("^[A-F,0-9]{6}$")][string]$MessageColor
)

# Hashtable for the body of Teams message
$Body = @{
            'text'= $MessageText
}

# Add the title of the Teams message, if exist
if($MessageTitle -ne ""){
            
            $Body.Add("Title", $MessageTitle)
}

# Add the color of the Teams message, if exist
if($MessageColor -ne ""){
            
            $Body.Add("themeColor", $MessageColor)
}

# Build the request
$Params = @{
         Headers = @{'accept'='application/json'}
         Body = $Body | ConvertTo-Json
         Method = 'Post'
         URI = $WebhookURL 
}

# Send the request to Microsoft Teams
Try{

    Invoke-RestMethod @Params 

}Catch{

    Write-Output "Error ! Impossible to publish this message in Microsoft Teams !"

}

