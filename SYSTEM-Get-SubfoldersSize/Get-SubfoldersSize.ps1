<#
.SYNOPSIS
	Specify a root folder and get the size of his subfolders

.DESCRIPTION

.PARAMETER 
    Edit directly the variable $RootFolder in the script

.EXAMPLE

.INPUTS

.OUTPUTS
	
.NOTES
	NAME:	Get-SubfoldersSize.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel

	VERSION HISTORY:

	1.0 	2021.02.02
		    Initial Version

#>
$RootFolder = "C:\TEMP\"
$FoldersSizeList = @()

Get-ChildItem -Force $RootFolder -ErrorAction SilentlyContinue -Directory | foreach{

    # Pour chaque dossier de notre racine, on calcul la taille
    $Size = 0
    $Size = (Get-ChildItem $_.Fullname -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum

    # Récupérer le nom complet du dossier (chemin)
    $FolderName = $_.fullname

    # Calculer la taille en Mb
    $FolderSize= [math]::Round($Size / 1Mb,2)

    # Ajouter un membre à notre objet global
    $FoldersSizeListObject = New-Object PSObject
    Add-Member -InputObject $FoldersSizeListObject -MemberType NoteProperty -Name "Dossier" -value $FolderName
    Add-Member -InputObject $FoldersSizeListObject -MemberType NoteProperty -Name "Taille-Mb" -value $FolderSize
    $FoldersSizeList += $FoldersSizeListObject
}

# Afficher le résultat dans un tableau
$FoldersSizeList | Out-GridView -Title "Taille des dossiers sous $RootFolder"