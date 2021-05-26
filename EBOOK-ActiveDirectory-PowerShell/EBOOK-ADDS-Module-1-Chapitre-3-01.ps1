# EBOOK-ADDS-Module-1-Chapitre-3-01.ps1
# Créer un domaine Active Directory via PowerShell

# Renommer le serveur et redémarrer 
Rename-Computer -NewName SRV-ADDS-01 -Force
Restart-Computer 

# Définir l'adresse IP
New-NetIPAddress -IPAddress "192.168.1.10" -PrefixLength "24" -InterfaceIndex (Get-NetAdapter).ifIndex -DefaultGateway "192.168.1.1" 

# Définir le DNS
Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter).ifIndex -ServerAddresses ("127.0.0.1") 

# Renommer la carte réseau
Rename-NetAdapter -Name Ethernet0 -NewName LAN 

# Ajouter les fonctionnalités nécessaires pour le rôle ADDS
$FeatureList = @("RSAT-AD-Tools","AD-Domain-Services","DNS")
Foreach($Feature in $FeatureList){

   if(((Get-WindowsFeature -Name $Feature).InstallState) -eq "Available"){

     Write-Output "Feature $Feature will be installed now !"

     Try{

        Add-WindowsFeature -Name $Feature -IncludeManagementTools -IncludeAllSubFeature

        Write-Output "$Feature : Installation is a success !"

     }Catch{

        Write-Output "$Feature : Error during installation !"
     }
   } # if(((Get-WindowsFeature -Name $Feature).InstallState) -eq "Available")
} # Foreach($Feature in $FeatureList) 

# Créer le domaine Active Directory
$DomainNameDNS = "it-connect.local"
$DomainNameNetbios = "IT-CONNECT"

$ForestConfiguration = @{
    '-DatabasePath'= 'C:\Windows\NTDS';
    '-DomainMode' = 'Default';
    '-DomainName' = $DomainNameDNS;
    '-DomainNetbiosName' = $DomainNameNetbios;
    '-ForestMode' = 'Default';
    '-InstallDns' = $true;
    '-LogPath' = 'C:\Windows\NTDS';
    '-NoRebootOnCompletion' = $false;
    '-SysvolPath' = 'C:\Windows\SYSVOL';
    '-Force' = $true;
    '-CreateDnsDelegation' = $false 
}

Import-Module ADDSDeployment
Install-ADDSForest @ForestConfiguration 
