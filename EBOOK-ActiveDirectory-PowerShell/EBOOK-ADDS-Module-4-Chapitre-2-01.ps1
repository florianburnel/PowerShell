# EBOOK-ADDS-Module-4-Chapitre-2-01.ps1
# Lister les rôles FSMO en PowerShell

# Valeurs cibles
$FSMOSchemaMaster = "SRV-ADDS-01.it-connect.local"
$FSMODomainNamingMaster = "SRV-ADDS-01.it-connect.local"
$FSMOPDCEmulator = "SRV-ADDS-01.it-connect.local"
$FSMORIDMaster = "SRV-ADDS-01.it-connect.local"
$FSMOInfrastructureMaster = "SRV-ADDS-01.it-connect.local"

# Fonction pour envoyer un e-mail en cas de changement
function Send-EmailAlert{

    param($Role,
           $ValeurCible,
           $ValeurProd)

    $SMTPServer = "serveur.smtp.fr"
    $SMTPFrom = "expediteur@domaine.fr"
    $SMTPTo = "destinataire@domaine.fr"

    Send-MailMessage -SmtpServer $SMTPServer -From $SMTPFrom -To $SMTPTo `
                     -Subject "Active Directory - Alerte FSMO $Role!" `
                     -Body "Alerte ! Changement de propriétaire pour le rôle FSMO $Role : $ValeurProd au lieu de $ValeurCible"

}

# Vérifier Role FSMO Schema Master
if((Get-ADForest it-connect.local).SchemaMaster -ne $FSMOSchemaMaster){ 
    Send-EmailAlert -Role "SchemaMaster" -ValeurCible $FSMOSchemaMaster -ValeurProd (Get-ADForest it-connect.local).SchemaMaster
}

# Vérifier Role FSMO Domain Naming Master
if((Get-ADForest it-connect.local).DomainNamingMaster -ne $FSMODomainNamingMaster){ 
    Send-EmailAlert -Role "DomainNamingMaster" -ValeurCible $FSMODomainNamingMaster -ValeurProd (Get-ADForest it-connect.local).DomainNamingMaster
}

# Vérifier Role FSMO PDC Emulator
if((Get-ADDomain it-connect.local).PDCEmulator -ne $FSMOPDCEmulator){ 
    Send-EmailAlert -Role "PDCEmulator" -ValeurCible $FSMOPDCEmulator -ValeurProd (Get-ADDomain it-connect.local).PDCEmulator
}

# Vérifier Role FSMO RID Master
if((Get-ADDomain it-connect.local).RIDMaster -ne $FSMORIDMaster){ 
    Send-EmailAlert -Role "RIDMaster" -ValeurCible $FSMORIDMaster -ValeurProd (Get-ADDomain it-connect.local).RIDMaster
}

# Vérifier Role FSMO Infrastructure Master
if((Get-ADDomain it-connect.local).InfrastructureMaster -ne $FSMOInfrastructureMaster){ 
    Send-EmailAlert -Role "InfrastructureMaster" -ValeurCible $FSMOInfrastructureMaster -ValeurProd (Get-ADDomain it-connect.local).InfrastructureMaster
}
