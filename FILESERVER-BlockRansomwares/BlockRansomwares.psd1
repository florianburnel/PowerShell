@{
	ClientName = "IT-Connect"

	Launcher = @{
        # Chemin vers le dossier où stocker les logs
        LogPath = "C:\Scripting\Logs\FSRM-BlockRansomwares"
        # Chemin vers le dossier où stocker les rapports
        ReportPath = "C:\Scripting\Logs\FSRM-BlockRansomwares\Rapports"
        # Mode d'exécution de l'API : Sync ou Incremental
        APIMode = "Sync"
	}

    FSRM = @{
        # Nom du groupe de fichiers
        FilesGroupName = "ITC_BlockRansomwares_Extensions"
        # Nom du modèle de filtre de fichiers
        FilesTemplateName = "ITC_BlockRansomwares_Template"
        # Nom du filtre de fichiers
        FilesFiltreName = "ITC_BlockRansomwares_Filtre"
        # Liste des extensions à exclure
        ExtensionsToExclude = @("")
        # Liste des extensions à inclure (en supplément de la liste de l'API)
        ExtensionsToInclude = @("")
	  # Protéger tous les partages
	  ProtectAllShares = $false
        # Liste des dossiers/volumes à protéger (le paramètre ProtectAllShares doit être à $false)
        DirToProtect = @("P:\")
	  # Exclure certains partages (le paramètre ProtectAllShares doit être à $true)
	  DirToExclude = @("C:\WINDOWS","C:\")
    }

    SMTP = @{
        # Serveur SMTP
        Server = "smtp.domaine.fr"
        # Adresse e-mail pour envoyer les e-mails
        SenderEmail = "expediateur@domaine.fr"
        # Adresse e-mail des destinaires (des alertes FSRM)
        RecipientsEmail = "destinataire1@domaine.fr;destinataire2@domaine.com"
        # Adresse e-mail des destinaires (des rapports e-mail du script)
        RecipientsEmailReport = @("destinataire1@domaine.fr","destinataire2@domaine.com")
    }
}