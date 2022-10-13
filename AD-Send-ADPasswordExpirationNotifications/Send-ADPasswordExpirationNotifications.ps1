<#
.SYNOPSIS
	Envoyer une notification par e-mail aux utilisateurs dont le mot de passe expire dans X jours

.EXAMPLE
    .\Send-ADPasswordExpirationNotifications.ps1
    
.INPUTS
.OUTPUTS
.NOTES
	NAME:	Send-ADPasswordExpirationNotifications.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	VERSION HISTORY:
        1.0   29/09/2022

#>
### Variables modifiables

# Nombre de jours avant l'expiration pour envoyer la notification
$DateThreshold = 7

# Serveur SMTP - Nom du serveur
$SMTPServer = "smtp.domaine.fr"

# Serveur SMTP - Numéro de port
$SMTPPort = 25

# Serveur SMTP - Adresse e-mail de l'expéditeur
$SMTPSender =  "notifications@domaine.fr"

# Serveur SMTP - Encodage Email
$SMTPEncoding =[System.Text.Encoding]::UTF8

# Envoyer une synthèse aux administrateurs
[boolean]$SendReportAdmin = $true

# Adresse e-mail du destinataire pour la synthèse
$SendReportAdminEmail = "rsi@domaine.fr"

### Fonctions
Function Send-MailMessageForUser{
    <#
        .SYNOPSIS : Envoyer une notification à un utilisateur dont le mot de passe expire dans X jours (selon seuil)
    #>

    Param([Parameter(Mandatory=$true)][string]$SendMailUserGivenName,
          [Parameter(Mandatory=$true)][string]$SendMailUserSurname,
          [Parameter(Mandatory=$true)][string]$SendMailUserEmail,
          [Parameter(Mandatory=$true)][string]$SendMailUserPrincipalName,
          [Parameter(Mandatory=$true)][string]$SendMailUserPasswordExpirationDate)

    # Corps de l'email pour les utilisateurs
    $SendMailBody=@"
<p>Bonjour $SendMailUserGivenName,</p>
<p>Dans <b>moins de $DateThreshold jours</b>, le mot de passe du compte <b>$SendMailUserPrincipalName</b> va expirer.<br>
<b>Pensez à le changer</b> avant qu'il arrive à expiration (date d'expiration : $SendMailUserPasswordExpirationDate)</p>
Cordialement,<br>
Le service informatique
"@

    # Objet de l'e-mail pour les utilisateurs
    $SendMailObject="$SendMailUserGivenName $SendMailUserSurname : votre mot de passe arrive à expiration !"

    # Envoyer l'e-mail
    Send-MailMessage -Verbose -SmtpServer $SMTPServer -Encoding $SMTPEncoding  `
        -From $SMTPSender -To $SendMailUserEmail `
        -Subject $SendMailObject `
        -Body $SendMailBody -BodyAsHtml -Port $SMTPPort

}

### Variables
# Date du jour (format FileTime)
$DateToday = (Get-Date).ToFileTime()

# Date de référence (date du jour + nombre jours avant expiration pour la notification)
$DateWithThreshold = (Get-Date).AddDays($DateThreshold).ToFileTime()

# Liste des utilisateurs Active Directory
$UsersInfos = Get-ADUser -Filter { (Enabled -eq $True) -and (PasswordNeverExpires -eq $False)} –Properties "DisplayName", "mail", "msDS-UserPasswordExpiryTimeComputed" | 
                         Select-Object -Property  "GivenName", "Surname","mail", "UserPrincipalName", "msDS-UserPasswordExpiryTimeComputed"

# Initialiser l'objet avec la liste des utilisateurs
$UsersNotifList=@()

# Traiter chaque utilisateur
Foreach($User in $UsersInfos){
    
    if(($User."msDS-UserPasswordExpiryTimeComputed" -lt $DateWithThreshold) -and ($User."msDS-UserPasswordExpiryTimeComputed" -gt $DateToday)){
            
            $UserPasswordExpirationDate = [datetime]::FromFileTime($User."msDS-UserPasswordExpiryTimeComputed")
            $UserObj = New-Object System.Object
            $UserObj | Add-Member -Type NoteProperty -Name GivenName -Value $User.GivenName
            $UserObj | Add-Member -Type NoteProperty -Name Surname -Value $User.Surname
            $UserObj | Add-Member -Type NoteProperty -Name Email -Value $User.mail
            $UserObj | Add-Member -Type NoteProperty -Name UserPrincipalName -Value $User.UserPrincipalName
            $UserObj | Add-Member -Type NoteProperty -Name PasswordExpirationDate -Value ($UserPasswordExpirationDate).ToString('dd/MM/yyyy')

            $UsersNotifList+=$UserObj

            Send-MailMessageForUser -SendMailUserGivenName $User.GivenName -SendMailUserSurname $User.Surname -SendMailUserEmail $User.mail `
                                    -SendMailUserPrincipalName $User.UserPrincipalName -SendMailUserPasswordExpirationDate ($UserPasswordExpirationDate).ToString('d MMMM yyyy')
    }
}

# Faut-il envoyer une synthèse aux administrateurs ?
if(($SendReportAdmin -eq $true) -and ($UsersNotifList.Count -ne 0)){

    # Corps de l'e-mail (sous la forme d'un tableau)
    $SendMailAdminBody = $UsersNotifList | ConvertTo-HTML -PreContent "Bonjour,<br><p>Voici la liste des comptes Active Directory dont le mot de passe expire dans moins de $DateThreshold jours.</p>" | Out-String | ForEach-Object{
                                    $_  -replace "<table>","<table style='border: 1px solid;'>" `
                                        -replace "<th>","<th style='border: 1px solid; padding: 5px; background-color:#014B83; color:#fff;'>" `
                                        -replace "<td>","<td style='padding: 10px;'>"
                                    }

    # Envoyer l'e-mail
    Send-MailMessage -Verbose -SmtpServer $SMTPServer -Encoding $SMTPEncoding  `
        -From $SMTPSender -To $SendReportAdminEmail `
        -Subject "Synthèse - Expiration des mots de passe AD - $(Get-Date -Format dd/MM/yyyy)" `
        -Body $SendMailAdminBody -BodyAsHtml -Port $SMTPPort
}