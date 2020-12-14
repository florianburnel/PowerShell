<#
.SYNOPSIS
    Cloner une machine virtuelle Hyper-V
.DESCRIPTION
    En s'appuyant sur les fonctionnalités d'export et d'importer d'Hyper-V, nous allons cloner
    une machine virtuelle existante. Cette version n'intègre pas de paramètres, il faut modifier les
    valeurs suivantes directement dans le script : $VMSourceName (VM source à cloner), $VMCloneName (nom du clone),
    $VMCloneExportPath (dossier dans lequel stocker l'export), $VMCloneImportConfigPath (dossier dans lequel créer les
    fichiers de configuration de la VM importée), $VMCloneImportVhdxPath (dossier dans lequel stocker les disques
    virtuels de la VM importée)
.EXAMPLE   
.INPUTS
.OUTPUTS
	
.NOTES
	NAME:	New-VMClone.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel
	VERSION HISTORY:
	1.0 	2020.12.06
		    Initial Version
#>
# Source
$VMSourceName = "Windows-10"

# Clone
$VMCloneName = "Windows-10-Clone"
$VMCloneExportPath = "C:\TEMP"
$VMCloneImportConfigPath = "C:\ProgramData\Microsoft\Windows\Hyper-V\Virtual Machines\Windows-10-Clone"
$VMCloneImportVhdxPath = "C:\ProgramData\Microsoft\Windows\Hyper-V\Virtual Machines\Windows-10-Clone\VHDX"

# On continue seulement si le nom du clone n'est pas déjà utilisé et si le nom du clone n'est pas identique au nom de la VM source
if((!(Get-VM -Name $VMCloneName -ErrorAction SilentlyContinue)) -and ($VMSourceName -ne $VMCloneName)){
    
    Write-Output "L'opération de clonage va débuter..."
    Write-Output "Première étape : exporter la VM ($VMSourceName)"

    if(Test-Path "$VMCloneExportPath"){

        # Exporter la VM
        Export-VM -Name $VMSourceName -Path $VMCloneExportPath -CaptureLiveState CaptureSavedState

        Write-Output "Deuxième étape : importer la VM en tant que copie"

        if(Test-Path "$VMCloneExportPath\$VMSourceName\Virtual Machines"){
            
            # Récupérer le nom du fichier VMCX de la VM exportée
            $FileVMCX = (Get-ChildItem -Path "$VMCloneExportPath\$VMSourceName\Virtual Machines" | Where{ $_.Name -match ".vmcx$" }).Name

            # Importer la VM en générant un nouvel ID pour créer le clone
            Import-VM -Path "$VMCloneExportPath\$VMSourceName\Virtual Machines\$FileVMCX" -Copy -GenerateNewId `
                      -VirtualMachinePath "$VMCloneImportConfigPath" `
                      -VhdDestinationPath "$VMCloneImportVhdxPath"
            
            # On vérifie que l'on trouve bien deux VM avec le même nom (puisque le clone n'est pas encore renommé)
            if((Get-VM -Name $VMSourceName).Count -eq 2){

                Write-Host "Il y a bien deux VMs avec le même nom, l'import est OK"
                Write-Host "Troisième étape : renommer la VM importée avec le nom du clone"

                # On renomme la VM
                Try{
                    $SearchVM = Get-VM | Where-Object {$_.Path.StartsWith("$VMCloneImportConfigPath")}
                    Rename-VM -VM $SearchVM -NewName $VMCloneName

                    Write-Output "Clone renommé avec succès : $VMCloneName"

                }Catch{
                    Write-Warning "Impossible de renommer la VM importée !"
                }

                # On indique une description à la VM et on déconnecte la carte réseau (sans la supprimer)
                if(Get-VM -Name $VMCloneName){

                    Set-VM -Name $VMCloneName -Notes "Clone de $VMSourceName"
                    Disconnect-VMNetworkAdapter -VMName $VMCloneName
                }

                # Suppression des données de l'export
                if(Test-Path "$VMCloneExportPath\$VMSourceName"){
                    Remove-Item -Path "$VMCloneExportPath\$VMSourceName" -Recurse -Force
                }
            }
                    
        }else{ Write-Warning "Impossible de trouver le dossier d'export de la VM source" }

    }else{ Write-Warning "Le dossier de destination pour l'export est introuvable !" }

}else{
    Write-Warning "L'opération de clonage est annulée car il existe déjà une VM nommée $VMCloneName"
}