<#
.SYNOPSIS
	Microsoft Teams : Generate a report of all teams with different informations

.DESCRIPTION
    Microsoft Teams : Generate a report of all teams with different informations such as team name, team owners, team members, etc.
	Export this information into a CSV file that you can open with Excel, for example.
	
	Before to call this function, you must establish a connection to Microsoft Teams and Exchange Online
	1 - Connect-ExchangeOnline
	2 - Connect-MicrosoftTeams 

.PARAMETER CSVPath
	This parameter must contain the full path (and filename with .csv) of the folder when you want store the report.
	
.EXAMPLE
	.\Get-TeamsReport.ps1 -CSVPath "C:\TEMP\TeamsReporting.csv"
   
.INPUTS
.OUTPUTS
	
.NOTES
	NAME:	Get-TeamsReport.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel
	VERSION HISTORY:
	1.0 	2021.05.26
		    Initial Version
#>

# Parameters
param(
    [parameter(Mandatory=$true)][string]$CSVPath = "C:\TEMP\TeamsReporting.csv"
)

Begin{
	$TeamList = Get-Team | Select-Object DisplayName,GroupID
	$TeamListReport = @()
}
	
Process{
	Write-Output "Patientez... Le rapport est en cours de création... ;-)"
	Write-Output ""

	Foreach ($Team in $TeamList)
	{      
			Write-Output "Traitement de l'équipe $($Team.DisplayName) en cours..." 

			# GUID Equipe
			$TeamGUID = $($Team.GroupId).ToString()
			   
			# Nom de l'équipe
			$TeamName = $Team.DisplayName

			# Date de création de l'équipe
			$TeamCreationDate = Get-UnifiedGroup -Identity $TeamGUID | Select -ExpandProperty WhenCreated

			# Canaux de l'équipe
			$TeamChannels = (Get-TeamChannel -GroupId $TeamGUID).DisplayName

			# Propriétaires de l'équipe
			$TeamOwner = (Get-TeamUser -GroupId $TeamGUID | Where{$_.Role -eq 'Owner'}).User

			# Nombre de membres dans l'équipe
			$TeamUserCount = (Get-TeamUser -GroupId $TeamGUID | Where{$_.Role -eq 'Member'}).Count
			if ($TeamUserCount -eq $null){ $TeamUserCount = 0 }

			# Liste des invités de l'équipe Teams
			$TeamGuest = (Get-TeamUser -GroupId $TeamGUID | Where{$_.Role -eq 'Guest'}).User | Foreach{ if($_ -ne $null){ $_.Split("#")[0] } }
			if ($TeamGuest -eq $null){ $TeamGuest = 0 }

			# Type d'accès à l'équipe Teams
			$TeamGroupAccessType = (Get-UnifiedGroup -identity $TeamGUID).AccessType
						
			# Générer un objet pour cette équipe (cumulatif)
			$TeamListReport = $TeamListReport + [PSCustomObject]@{
													TeamName = $TeamName; 
													TeamCreationDate = $TeamCreationDate; 
													TeamChannels = $TeamChannels -join ', ';
													TeamOwners = $TeamOwner -join ', ';
													TeamMemberCount = $TeamUserCount;
													TeamAccessType = $TeamGroupAccessType;
													TeamGuests = $TeamGuest -join ',';
													}
	}
}
	
End{
	$TeamListReport | Export-Csv $CSVPath -Delimiter ";" -Encoding UTF8 -NoTypeInformation
}