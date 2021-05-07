# EBOOK-ADDS-Module-4-Chapitre-5-01.ps1
# Utiliser PowerShell pour identifier les ordinateurs et utilisateurs inactifs

$InactivesObjects = Search-ADaccount -AccountInactive -Timespan 180 | Where{ ($_.DistinguishedName -notmatch "CN=Users") -and ($_.Enabled -eq $true) } | foreach{
        
        if(($_.objectClass -eq "user") -and (Get-ADUser -Filter "Name -eq '$($_.Name)'" -Properties WhenCreated).WhenCreated -lt (Get-Date).AddDays(-7)){ $_ }
        if(($_.objectClass -eq "computer") -and (Get-ADComputer -Filter "Name -eq '$($_.Name)'" -Properties WhenCreated).WhenCreated -lt (Get-Date).AddDays(-7)){ $_ }
}

Foreach($Object in $InactivesObjects){

    $SamAccountName = $Object.SamAccountName
    $DN = $Object.DistinguishedName
    $ObjectClass = $Object.ObjectClass

    Write-Output "L'objet $SamAccountName est inactif !"

    # Si c'est un utilisateur...
    if($ObjectClass -eq "user"){

      # Retirer l'utilisateur des groupes (sauf "Utilisateurs du domaine")
      Get-AdPrincipalGroupMembership -Identity $SamAccountName | Where-Object { $_.Name -Ne "Utilisateurs du domaine" } | Remove-AdGroupMember -Members $SamAccountName -Confirm:$false -ErrorVariable ClearObject

      # Désactiver l'utilisateur
      Set-ADUser -Identity $SamAccountName -Enabled:$false -Description "Désactivé le $(Get-Date -Format dd/MM/yyyy)" -ErrorVariable +ClearObject

    # Sinon, si c'est un ordinateur...
    }elseif($ObjectClass -eq "computer"){

      # Retirer l'ordinateur des groupes (sauf "Ordinateurs du domaine")
      Get-AdPrincipalGroupMembership -Identity $SamAccountName | Where-Object { $_.Name -Ne "Ordinateurs du domaine" } | Remove-AdGroupMember -Members $SamAccountName -Confirm:$false -ErrorVariable ClearObject

      # Désactiver l'ordinateur
      Set-ADComputer -Identity $SamAccountName -Enabled:$false -Description "Désactivé le $(Get-Date -Format dd/MM/yyyy)" -ErrorVariable +ClearObject
    }

    # Déplacer l'utilisateur/ordinateur
    Move-ADObject -Identity "$DN" -TargetPath "OU=Archivage,DC=IT-CONNECT,DC=LOCAL" -ErrorVariable +ClearObject

    if($ClearUser){
      Write-Output "ERREUR ! objet concerné : $SamAccountName ($ObjectClass)"
    }else{
      Write-Output "Traitement de l'objet $SamAccountName de type $ObjectClass avec succès ! :-)"
    }

    Clear-Variable ClearUser -ErrorAction SilentlyContinue
} 
