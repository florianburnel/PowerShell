<#

    .SYNOPSYS - Protéger les partages contre les ransomwares (bloquer des extensions)

    .NOTES
	 NAME:	BlockRansomwares.ps1
	 AUTHOR:	Florian Burnel
	 EMAIL:	florian.burnel@it-connect.fr
	 WWW:	www.it-connect.fr
	 TWITTER: @FlorianBurnel

#>
# Parameters
param(
    [parameter(Mandatory=$false)][ValidateScript({Test-Path $_})][String]$Config = $PSScriptRoot
)

# Importer la configuration
$ClientConfig = Import-LocalizedData -BaseDirectory $Config -FileName BlockRansomwares.psd1 -ErrorAction SilentlyContinue

# Si l'on ne trouve pas le fichier de configuration, on ferme le script
if($ClientConfig -eq $null){
  
  Write-Host -ForegroundColor Red "Impossible de trouver le fichier de configuration : $Config\BlockRansomwares.psd1"
  Start-Sleep -Seconds 10
  exit
}

# Valeurs issues du fichier de configuration
$ClientName = $ClientConfig.ClientName
$LogPath = $ClientConfig.Launcher.LogPath
$ReportPath = $ClientConfig.Launcher.ReportPath
$APIMode = $ClientConfig.Launcher.APIMode

# Options FSRM
$FSRM_FilesGroupName = $ClientConfig.FSRM.FilesGroupName
$FSRM_FilesTemplateName = $ClientConfig.FSRM.FilesTemplateName
$FSRM_FilesFiltreName = $ClientConfig.FSRM.FilesFiltreName
$FSRM_ExtensionsToExclude = $ClientConfig.FSRM.ExtensionsToExclude
$FSRM_ExtensionsToInclude = $ClientConfig.FSRM.ExtensionsToInclude
$FSRM_ProtectAllShares = $ClientConfig.FSRM.ProtectAllShares
$FSRM_DirToProtect = $ClientConfig.FSRM.DirToProtect
$FSRM_DirToExclude = $ClientConfig.FSRM.DirToExclude

# Options SMTP
$SMTP_Server = $ClientConfig.SMTP.Server
$SMTP_SenderEmail = $ClientConfig.SMTP.SenderEmail
$SMTP_RecipientsEmail = $ClientConfig.SMTP.RecipientsEmail
$SMTP_RecipientsEmailReport = $ClientConfig.SMTP.RecipientsEmailReport 

# Constantes
$DateOnlyShort = Get-Date -Format "yyyyMMdd_HHmmss"
$LogFile = "$LogPath\BlockRansomwares_$DateOnlyShort.log"
$ReportFile = "$ReportPath\BlockRansomwares_$DateOnlyShort.csv"

# Fonctions
function Write-Log {
    <#
        .SYNOPSIS : Ecrire un message de log dans un fichier de log
    #>

   param (  [Parameter(Mandatory)][string]$Message,
            [Parameter(Mandatory)][string]$LogFile,
            [Parameter(Mandatory)][string]$Messagetype,
            [boolean]$IncludeTimestamp = $true )
       
   if(($IncludeTimestamp -eq $true) -and ($Messagetype -ne "REPORT")){
   
       $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
       $Line = '{2} {1}: {0}'
       $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy)
       $Line = $Line -f $LineFormat

    }else{

       $Line = $Message
    }

    # Couleur du message
    Switch -Wildcard ($Messagetype) {
        "OK" { $Color = "Green" ; break }
        "INFO" { $Color = "White" ; break }
        "REPORT" { $Color = "White" ; break }
        "WARNING" { $Color = "Yellow" ; break }
        "ERROR" { $Color = "Red" ; break }
        "STEP" { $Color = "Cyan" ; break }
        default { $Color = "white" }
    }

    Add-Content -Value $Line -Path $LogFile
    Write-Host $Line -ForegroundColor $Color
}

# Début du traitement
Write-Log -LogFile $LogFile -Messagetype "STEP" -Message "#######################################################"
Write-Log -LogFile $LogFile -Messagetype "STEP" -Message "BlockRansomwares - $ClientName"
Write-Log -LogFile $LogFile -Messagetype "STEP" -Message "#######################################################"

# vérifier si le mode est correct avant de poursuivre
if($APIMode -notin ("Sync","Incremental")){ 
    Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR ! Le mode de l'API n'est pas pris en charge ($APIMode) !"
    Start-Sleep -Seconds 5
    exit 
}else{
    Write-Log -LogFile $LogFile -Messagetype "INFO" -Message "INFO - L'API est configurée en mode $APIMode"
}

###
# Partie 1 - Groupe d'extensions de fichiers
###
Write-Log -LogFile $LogFile -Messagetype "STEP" -Message "Partie 1 - Gérer la liste des extensions de fichiers"

# Récupérer la liste des extensions depuis l'API
# Old : $FSRMapi = "https://fsrm.experiant.ca/api/v1/get" (plus maintenu)
$FSRMapi =  "https://raw.githubusercontent.com/DFFspace/CryptoBlocker/master/KnownExtensions.txt"
$FSRMapiJsonExt = ((Invoke-WebRequest $FSRMapi -UseBasicParsing -ContentType 'application/json; charset=UTF-8').Content | ConvertFrom-Json).filters
$FSRMapiExtCount = $FSRMapiJsonExt.Count

# S'assurer que la liste des extensions récupérées n'est pas vide
if($FSRMapiExtCount -eq 0){

    Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR ! La liste des extensions récupérées auprès de l'API est vide !"
    exit
}else{
    Write-Log -LogFile $LogFile -Messagetype "OK" -Message "Nombre d'extensions récupérées à partir de l'API : $FSRMapiExtCount"
}

# Ajuster la liste des extensions pour inclure/exclure des extensions selon le fichier de configuration (ajout puis exclusion)
$FSRMapiJsonExt = $FSRMapiJsonExt + $FSRM_ExtensionsToInclude
$FSRMapiJsonExt = $FSRMapiJsonExt | Where{ $_ -ne $FSRM_ExtensionsToExclude }

# Vérifier l'existence du Groupe d'extensions de fichiers : le mettre à jour s'il existe, sinon le créer (et ajouter les extensions).
if(Get-FsrmFileGroup -Name $FSRM_FilesGroupName -ErrorAction SilentlyContinue){

    Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - Groupe d'extensions de fichiers trouvé ($FSRM_FilesGroupName)"

    # Booléen - Par défaut, on part du principe que la liste ne doit pas être modifiée
    [boolean]$FSRMExtListUpdate = $false

    # Liste des extensions actuellement en production
    $FSRMProdExt = (Get-FsrmFileGroup -Name $FSRM_FilesGroupName).IncludePattern

    ## Comparer les deux listes pour journaliser
    # Extensions qui vont être ajoutées
    $FSRMProdAdd = (Compare-Object -DifferenceObject $FSRMapiJsonExt -ReferenceObject $FSRMProdExt -ErrorAction SilentlyContinue `
                                                            | Where-Object {$_.SideIndicator -eq "=>"}).InputObject
    
    # Ajouter dans le fichier de log les nouvelles extensions qui vont être ajoutées
    if($FSRMProdAdd.Count -gt 0){
        Write-Log -LogFile $LogFile -Messagetype "INFO" -Message "INFO - Il y a $($FSRMProdAdd.Count) extensions à ajouter"  
        Write-Log -LogFile $LogFile -Messagetype "INFO" -Message "INFO - Voici la liste : $FSRMProdAdd"
        $FSRMExtListUpdate = $true
    }else{
        Write-Log -LogFile $LogFile -Messagetype "INFO" -Message "INFO - Pas de nouvelle extension à ajouter à la liste d'extensions."  
    }

    # Il n'y a que quand l'API est en mode "Sync" que l'on supprime des entrées (potentiellement) car on synchronise avec le contenu de l'API
    if($APIMode -eq "Sync"){

        # Extensions qui vont être supprimées
        $FSRMProdDel = (Compare-Object -DifferenceObject $FSRMapiJsonExt -ReferenceObject $FSRMProdExt -ErrorAction SilentlyContinue `
                                                                | Where-Object {$_.SideIndicator -eq "<="}).InputObject

        # Ajouter dans le fichier de log les extensions supprimées/exclues
        if($FSRMProdDel.Count -gt 0){
            Write-Log -LogFile $LogFile -Messagetype "INFO" -Message "INFO - Il y a $($FSRMProdDel.Count) extensions à supprimer"  
            Write-Log -LogFile $LogFile -Messagetype "INFO" -Message "INFO - Voici la liste : $FSRMProdDel"
            $FSRMExtListUpdate = $true
        }else{
            Write-Log -LogFile $LogFile -Messagetype "INFO" -Message "INFO - Pas d'extension à supprimer de la liste d'extensions."  
        }
    }

    # Si l'API est en mode "Incremental", il faut ajouter à la liste existante les nouvelles extensions, sans en retirer
    if(($APIMode -eq "Incremental") -and ($FSRMProdAdd.Count -gt 0)){
        
        $FSRMExtList = $FSRMProdExt + $FSRMProdAdd
        Write-Log -LogFile $LogFile -Messagetype "INFO" -Message "INFO - La nouvelle liste va contenir $($FSRMExtList.Count) extensions."  

    }elseif($APIMode -eq "Sync"){
        $FSRMExtList = $FSRMapiJsonExt
    }

    if($FSRMExtListUpdate -eq $true){

        # Mettre à jour le Groupe d'extensions de fichiers (écraser la liste existente par la nouvelle liste), s'il y a des changements
        Try{
            Set-FsrmFileGroup -Name $FSRM_FilesGroupName -IncludePattern $FSRMExtList -ErrorAction Stop
            Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - Liste des extensions de fichiers actualisée dans FSRM ($FSRM_FilesGroupName)"        
        }Catch{
            Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR - Impossible de mettre à jour le groupe d'extensions de fichiers ($FSRM_FilesGroupName - $($_.Exception.Message))"   
        }
    }

}else{

    Write-Log -LogFile $LogFile -Messagetype "WARNING" -Message "Remarque - Le groupe d'extensions de fichiers avec le nom $FSRM_FilesGroupName va être créé !"

    # Alimenter la variable $FSRMProdAdd pour le rapport (uniquement)
    $FSRMProdAdd = $FSRMapiJsonExt

    Try{
        New-FsrmFileGroup -Name $FSRM_FilesGroupName -IncludePattern $FSRMapiJsonExt -ErrorAction Stop
        Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - Création du groupe d'extensions de fichiers avec le nom $FSRM_FilesGroupName ($FSRMapiExtCount extensions ajoutées)"
        
    }Catch{
        Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR - Impossible de créer le groupe d'extensions de fichiers ($FSRM_FilesGroupName - $($_.Exception.Message))"   
    }
} # if(Get-FsrmFileGroup -Name $FSRM_FilesGroupName -ErrorAction SilentlyContinue)

###
# Partie 2 - Modèle de filtre de fichiers
###
Write-Log -LogFile $LogFile -Messagetype "STEP" -Message "Partie 2 - Gérer le modèle de filtre de fichiers"

$FSRM_NotifEvent = New-FsrmAction -Type Event -EventType Warning `
                                    -Body "L'utilisateur [Source Io Owner] a tenté de sauvegarder le fichier [Source File Path] dans [File Screen Path] sur le serveur [Server]. Cette extension est contenue dans le groupe [Violated File Group], et elle n'est pas autorisée sur ce serveur." -RunLimitInterval 30

$FSRM_NotifEmail = New-FsrmAction -Type Email -MailTo "[Admin Email]" -Subject "Alerte - Ransomware !" `
                                    -Body "L'utilisateur [Source Io Owner] a tenté d'enregistrer [Source File Path] dans [File Screen Path] sur le serveur [Server]. Ce fichier se trouve dans le groupe de fichiers [Violated File Group], qui n'est pas autorisé sur le serveur." -RunLimitInterval 30 


if(Get-FsrmFileScreenTemplate -Name $FSRM_FilesTemplateName -ErrorAction SilentlyContinue){

    Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - Groupe d'extensions de fichiers trouvé ($FSRM_FilesGroupName)"

    # S'assurer que le groupe d'extensions est bien associé à ce template
    if($FSRM_FilesGroupName -in (Get-FsrmFileScreenTemplate -Name $FSRM_FilesTemplateName).IncludeGroup){
        Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - Le modèle $FSRM_FilesTemplateName contient bien le groupe d'extensions $FSRM_FilesGroupName"
    }else{
        Set-FsrmFileScreenTemplate -Name $FSRM_FilesTemplateName -IncludeGroup $FSRM_FilesGroupName
        Write-Log -LogFile $LogFile -Messagetype "WARNING" -Message "ATTENTION - Le groupe d'extensions n'était pas associé à ce modèle (OK désormais)."
    }

}else{

    Write-Log -LogFile $LogFile -Messagetype "WARNING" -Message "Remarque - Le modèle de filtre de fichiers avec le nom $FSRM_FilesGroupName va être créé !"

    Try{
        New-FsrmFileScreenTemplate -Name $FSRM_FilesTemplateName -Active:$True -IncludeGroup "$FSRM_FilesGroupName" -Notification $FSRM_NotifEvent,$FSRM_NotifEmail
        Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - Création du modèle de filtre de fichiers avec le nom $FSRM_FilesTemplateName"
        
    }Catch{
        Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR - Impossible de créer le modèle de filtre de fichiers avec le nom $FSRM_FilesTemplateName $($_.Exception.Message))"   
    }
} # if(Get-FsrmFileGroup -Name $FSRM_FilesTemplateName -ErrorAction SilentlyContinue)

###
# Partie 3 - Appliquer le filtre sur les partages
###
Write-Log -LogFile $LogFile -Messagetype "STEP" -Message "Partie 3 - Appliquer le filtre sur les partages"

# Récupérer la liste des filtres actuels
$FSRM_FileScreenProd = Get-FsrmFileScreen

# Déterminer la liste des dossiers à protéger
if($FSRM_ProtectAllShares -eq $true){

    # Récupérer les chemins de tous les partages de fichiers du serveur local
    $DirToProtectList = Get-CimInstance Win32_Share | Select Name,Path,Type | Where-Object { ($_.Type -match  '0|2147483648') -and ($_.Path -notin $FSRM_DirToExclude) } | Select -ExpandProperty Path | Select -Unique 

}elseif($FSRM_ProtectAllShares -eq $false){
    $DirToProtectList = $FSRM_DirToProtect
}


# Ajouter les en-têtes au rapport
Add-Content -Path $ReportFile -Value "Dossiers;Etat"

# Configurer la protection pour chaque dossier ou volume, selon le fichier de configuration
Foreach($DirToProtect in $DirToProtectList){

    if(Test-Path $DirToProtect -ErrorAction SilentlyContinue){
        Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - $DirToProtect - Le chemin est valide, la protection FSRM va être ajoutée..."

        # Si le répertoire est déjà dans la liste des filtres, on vérifie sa configuration (et la rectifie si besoin), sinon on crée le filtre
        if($DirToProtect -in $FSRM_FileScreenProd.Path){
            
            # Si le filtre contient est déjà associé à la liste d'extension ransomware, c'est OK, sinon on modifie le filtre
            if((Get-FsrmFileScreen -Path $DirToProtect).IncludeGroup -contains $FSRM_FilesGroupName){

                Write-Log -LogFile $LogFile -Messagetype "INFO" -Message "INFO - $DirToProtect - Le filtre d'extension $FSRM_FilesGroupName est déjà associé au filtre de fichiers"
                Add-Content -Path $ReportFile -Value "$DirToProtect;OK - Aucune modification apportée"

            }else{
                $FSRM_FilesGroupToInclude = (Get-FsrmFileScreen -Path $DirToProtect).IncludeGroup + $FSRM_FilesGroupName

                Try{
                    Set-FsrmFileScreen -Path $DirToProtect -IncludeGroup $FSRM_FilesGroupToInclude -ErrorAction Stop
                    Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - $DirToProtect - Le filtre d'extension $FSRM_FilesGroupName a été ajouté correctement"
                    Add-Content -Path $ReportFile -Value "$DirToProtect;Mis à jour"

                }Catch{
                    Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR - $DirToProtect - Impossible de mettre à jour la liste de filtre d'extension ($($_.Exception.Message))" 
                    Add-Content -Path $ReportFile -Value "$DirToProtect;Erreur - Actualisation du filtre impossible"                      
                }
            }

        }else{

            Try{
                New-FsrmFileScreen -Path $DirToProtect -IncludeGroup $FSRM_FilesGroupName -Template $FSRM_FilesTemplateName -Active:$true
                Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - $DirToProtect - Le filtre a été correctement configuré sur cette cible"
                Add-Content -Path $ReportFile -Value "$DirToProtect;OK - Filtre créé"

            }Catch{
                Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR - $DirToProtect - Impossible de créer le filtre de protection sur cette cible ($($_.Exception.Message))"  
                Add-Content -Path $ReportFile -Value "$DirToProtect;Erreur - Création du filtre impossible" 
            }
        }

    }else{
        Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR - Ce répertoire ne sera pas protégé car il n'existe pas ou il est inaccessible : $DirToProtect"
        Add-Content -Path $ReportFile -Value "$DirToProtect;Erreur - Chemin introuvable" 
    }

    Clear-Variable DirToProtect,FSRM_FilesGroupToInclude -ErrorAction SilentlyContinue
}

###
# Partie 4 - Configurer le SMTP de FSRM
###
Write-Log -LogFile $LogFile -Messagetype "STEP" -Message "Partie 4 - Configurer le SMTP dans FSRM"

if(($SMTP_Server -ne "") -and ($SMTP_RecipientsEmail -ne "") -and ($SMTP_SenderEmail -ne "")){

    Write-Log -LogFile $LogFile -Messagetype "OK" -Message "INFO - Serveur SMTP : $SMTP_Server - Expéditeur : $SMTP_SenderEmail - Destinataires : $SMTP_RecipientsEmail"    

    Try{
        Set-FsrmSetting -SmtpServer $SMTP_Server -FromEmailAddress $SMTP_SenderEmail -AdminEmailAddress $SMTP_RecipientsEmail
        Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - Configuration SMTP effectuée avec succès !"    
    }Catch{
        Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR - Impossible d'effectuer la configuration SMTP ($($_.Exception.Message))"   
    }
}else{
    Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR - Les paramètres de configuration SMTP sont incorrects !"
}

###
# Partie 5 - Envoyer un rapport par e-mail
###
Write-Log -LogFile $LogFile -Messagetype "STEP" -Message "Partie 5 - Générer et envoyer le rapport par e-mail"

# Exporter le CSV au format HTML
$ExportHTML = "$ReportPath\Rapport_$DateOnlyShort.html"

# E-mail : encodage
$EmailEncoding = [System.Text.Encoding]::UTF8

# Si le mode est "Incremental" on spécifie dans le rapport aucune extension supprimée
if($APIMode -eq "Incremental"){ $FSRMProdDel = "-" }

# Style CSS
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: #07246A;border-collapse: collapse; padding: 5px; font-family: Calibri;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: #07246A;background-color: #07246A; color: white; font-family: Calibri;}
TD {border-width: 1px;padding: 10px;border-style: solid;border-color: #07246A; font-family: Calibri;}
</style>
"@

    $LogReportEmail = Import-Csv -Path $ReportFile -Delimiter ";" -Encoding Default

    $LogReportEmail | Select-Object Dossiers,Etat |
                  ConvertTo-HTML -Head $Header -PreContent "<h2 style='border-bottom: 2px solid; padding-bottom: 15px;'>$ClientName - FSRM Block Ransomwares - $(Get-Date -Format "dd/MM/yyyy à HH:mm")</h2>
                                                            <table>
                                                            <thead>
                                                              <tr style='background-color:#014B83; color:#fff; text-align:left;'>
                                                                <th style='padding: 5px;'>Paramètres</th>
                                                                <th style='padding: 5px;'>Valeurs</th>
                                                              </tr>
                                                            </thead>
                                                            <tbody>
                                                              <tr>
                                                                <td style='padding: 5px;'>Mode API</td>
                                                                <td>$APIMode</td>
                                                              </tr>
                                                              <tr>
                                                                <td style='padding: 5px;'>Extensions ajoutées</td>
                                                                <td>$FSRMProdAdd</td>
                                                              </tr>
                                                              <tr>
                                                                <td style='padding: 5px;'>Extensions supprimées</td>
                                                                <td>$FSRMProdDel</td>
                                                              </tr>
                                                            </tbody>
                                                            </table><br/>" | 
                  Foreach{ 
                
                    if( $_ -match "<td>OK" ){

                        $_ -replace "<td>OK" , "<td style='background-color : #D2FECD;'>OK"
                    
                    }elseif($_ -match "<td>Erreur"){

                        $_ -replace "<td>Erreur" , "<td style='background-color : #FFBFBF; color: #fff;'>Erreur"
                    
                    }elseif($_ -match "<td>Mis"){

                        $_ -replace "<td>Mis" , "<td style='background-color : #FFCC00;'>Mis"

                    }else{

                        $_
                    }
               
                  } | Out-File $ExportHTML

    $HTMLContent = Get-Content $ExportHTML | Out-String

Try{
    # Envoyer le rapport HTML par e-mail
    Send-MailMessage -Verbose -SmtpServer $SMTP_Server -Encoding $EmailEncoding  `
        -From $SMTP_SenderEmail -To $SMTP_RecipientsEmailReport `
        -Subject "$ClientName - Rapport FSRM du $DateOnlyShort" `
        -Body $HTMLContent -BodyAsHtml -ErrorAction Stop

    Write-Log -LogFile $LogFile -Messagetype "OK" -Message "OK - Rapport d'exécution envoyé par e-mail avec succès !"

}Catch{
    Write-Log -LogFile $LogFile -Messagetype "ERROR" -Message "ERREUR - Impossible d'envoyer le rapport par e-mail ($($_.Exception.Message))"
}