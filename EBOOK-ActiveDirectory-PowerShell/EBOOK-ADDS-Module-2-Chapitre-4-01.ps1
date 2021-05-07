# EBOOK-ADDS-Module-2-Chapitre-4-01.ps1
# Modifier le mot de passe d'un compte AD avec PowerShell

# Exemple de fichier CSV
#SamAccountName;Password
#j.doeuf;B0nJ0uR*50
#s.fonfek;B0n$0!R*14 

# Controleur de domaine cible
$Server = "SRV-ADDS-01"

# Chemin vers le fichier CSV
$fichier = "C:\Scripting\CSV\Users_Password.csv"

# Importer le fichier CSV
$users = Import-Csv -Path $fichier -Delimiter ";" -Encoding UTF8

# Pour chaque ligne du CSV... (Pour chaque utilisateur)
foreach($user in $users){

    # Récupère le SamAccountName de l'utilisateur
    $UserSAM = $user.SamAccountName

    # Récupérer le mot de passe de l'utilisateur
    $UserPwd = $user.Password

    Set-ADAccountPassword -Server $Server -Identity $UserSAM -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $UserPwd -Force)
} 
