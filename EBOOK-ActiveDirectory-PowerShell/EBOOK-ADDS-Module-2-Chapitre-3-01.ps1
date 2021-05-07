# EBOOK-ADDS-Module-2-Chapitre-3-01.ps1
# Créer des utilisateurs dans l’AD à partir d’un CSV

# Exemple de fichier CSV
#Prenom;Nom;Fonction
#Gérard;Mensoif;Directeur
#Sophie;Fonfek;Secrétaire
#John;Doeuf;Comptable
#Juda;Nanas;Secrétaire
#Cécile;Ourkessa;Secrétaire

$CSVFile = "C:\Scripts\AD_USERS\Utilisateurs.csv"
$CSVData = Import-CSV -Path $CSVFile -Delimiter ";" -Encoding UTF8

Foreach($Utilisateur in $CSVData){

    $UtilisateurPrenom = $Utilisateur.Prenom
    $UtilisateurNom = $Utilisateur.Nom
    $UtilisateurLogin = ($UtilisateurPrenom).Substring(0,1).ToLower() + "." + $UtilisateurNom.ToLower()
    $UtilisateurEmail = "$UtilisateurLogin@it-connect.fr"
    $UtilisateurMotDePasse = "IT-Connect@2020"
    $UtilisateurFonction = $Utilisateur.Fonction

    # Vérifier la présence de l'utilisateur dans l'AD
    if (Get-ADUser -Filter {SamAccountName -eq $UtilisateurLogin})
    {
        Write-Warning "L'identifiant $UtilisateurLogin existe déjà dans l'AD"
    }
    else
    {

        New-ADUser -Name "$UtilisateurNom $UtilisateurPrenom" `
                    -DisplayName "$UtilisateurNom $UtilisateurPrenom" `
                    -GivenName $UtilisateurPrenom `
                    -Surname $UtilisateurNom `
                    -SamAccountName $UtilisateurLogin `
                    -UserPrincipalName "$UtilisateurLogin@it-connect.local" `
                    -EmailAddress $UtilisateurEmail `
                    -Title $UtilisateurFonction `
                    -Path "OU=Personnel,DC=IT-CONNECT,DC=LOCAL" `
                    -AccountPassword(ConvertTo-SecureString $UtilisateurMotDePasse -AsPlainText -Force) `
                    -ChangePasswordAtLogon $true `
                    -Enabled $true

        Write-Output "Création de l'utilisateur : $UtilisateurLogin ($UtilisateurNom $UtilisateurPrenom)"
    }
} 
