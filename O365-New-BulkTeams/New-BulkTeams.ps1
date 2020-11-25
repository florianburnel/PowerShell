<#
.SYNOPSIS
    Créer des équipes Teams en masse à partir d'un fichier CSV source
.DESCRIPTION
    A partir d'un fichier CSV source avec trois colonnes (Equipe, Email et Role), le script va créer des équipes Teams.
    Pour chacune de ces équipes, il va ajouter les membres et les propriétaires déclarés dans le fichier CSV.
.EXAMPLE   
.INPUTS
.OUTPUTS
	
.NOTES
	NAME:	New-BulkTeams.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel
	VERSION HISTORY:
	1.0 	2020.11.25
		    Initial Version
#>

# Installer le module
Install-Module -Name MicrosoftTeams

# Récupérer les identifiants
$Credentials = Get-Credential 
$Credentials.password.MakeReadOnly()

# Se connecter à Teams
Connect-MicrosoftTeams -Credential $Credentials

# Importer les données du CSV
$CSV = Import-Csv -Path "C:\TEMP\Equipes.csv" -Delimiter ";" -Encoding UTF8

# Liste des équipes à créer
$TeamsToCreate = ($CSV | Select-Object Equipe -Unique).Equipe

# Création des équipes Teams
Foreach($Team in $TeamsToCreate){

     Try{
          New-Team -DisplayName $Team -Description "Equipe pour $Team" -MailNickName $Team `
               -AllowGiphy $false -AllowStickersAndMemes $false `
              -ErrorAction SilentlyContinue -InformationAction SilentlyContinue
    
          Write-Output "OK : équipe Teams $Team créée avec succès !"

     }Catch{

          Write-Output "ERREUR lors de la création de l'équipe Teams : $Team"
     }
}

# Ajouter les utilisateurs aux équipes
$TeamListing = Get-Team

foreach($User in $CSV){
    
    # Si l'équipe est bien dans la liste des équipes créées...
    if($User.Equipe -in $TeamListing.DisplayName){

        Write-Host "Equipe $($User.Equipe) trouvée : $($User.Email) va être ajouté en tant que $($User.Role)"
        $TeamGroupId = ($TeamListing | Where{ $_.DisplayName -eq $User.Equipe } ).GroupId

        # Définir le rôle à partir du fichier CSV
        if($User.Role -eq "propriétaire"){ 
        
            $TeamRole = "owner"
        
        }else{

            $TeamRole = "member"
        }

        # On ajoute l'utilisateur dans l'équipe
        Try{

            Add-TeamUser -GroupId $TeamGroupId -User $User.Email -Role $TeamRole -ErrorAction SilentlyContinue
            Write-Host "Equipe $($User.Equipe) : $($User.Email) ajouté avec succès !"
        
        }Catch{

            Write-Host "Equipe $($User.Equipe) : ERREUR avec $($User.Email) !"
        }

    }else{

        write-host "ERREUR ! Impossible de trouver l'équipe suivante : $($User.Equipe)"
    }

    Clear-Variable TeamGroupId
}

# Lister les membres d'une équipe spécifique identifiée par son GroupId
Get-TeamUser -GroupId $TeamGroupId