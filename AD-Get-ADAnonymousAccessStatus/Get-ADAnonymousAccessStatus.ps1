<#PSScriptInfo
    .VERSION 1.0.1
    .GUID cd46c714-bb58-4416-947b-1691b8185859
    .AUTHOR florian.burnel
    .TAGS ActiveDirectory
    .LICENSEURI
    .PROJECTURI https://github.com/florianburnel/PowerShell/tree/master/AD-Get-ADAnonymousAccessStatus
    .ICONURI
    .EXTERNALMODULEDEPENDENCIES
    .REQUIREDSCRIPTS 
    .EXTERNALSCRIPTDEPENDENCIES 
    .RELEASENOTES
    .DESCRIPTION This script query the Active Directory to check the unicode value "dsHeuristics". The 7th value of this settings determine if anonymous access is authorized or not in your environment. So, if the value if "not defined", it's OK because equal 0. But if the value is 2, it's bad !
#>

<#
.DESCRIPTION
        
         This script query the Active Directory to check the unicode value "dsHeuristics".
         The 7th value of this settings determine if anonymous access is authorized or not in your environment.
         So, if the value if "not defined", it's OK because equal 0. But if the value is 2, it's bad !
        
        .NOTES
	     NAME:	Get-ADAnonymousAccessStatus.ps1
	     AUTHOR:	Florian Burnel
	     EMAIL:	florian.burnel@it-connect.fr
         URL : www.it-connect.fr
	     TWITTER: @FlorianBurnel
        
        .EXAMPLE        
         PS> .\Get-ADAnonymousAccessStatus.ps1
   
        .PARAMETER
         NO PARAMETER.


	    VERSION HISTORY:
	        
        1.0.0 	2018.01.25
	            Initial Version
				
		1.0.1   2018.01.25
				Add block "PSScriptInfo" for PowerShell Gallery
#>

$TargetDN = ("CN=Directory Service,CN=Windows NT,CN=Services,CN=Configuration," + (Get-ADDomain).DistinguishedName)
$ValuedsHeuristics = (Get-ADObject -Identity $TargetDN -Properties dsHeuristics).dsHeuristics

if(($ValuedsHeuristics -eq "") -or ($ValuedsHeuristics.Length -lt 7)){
    
    Write-Output "Good ! Anonymous access is already disable !"

}elseif(($ValuedsHeuristics.Length -ge 7) -and ($ValuedsHeuristics[6] -eq "2")){

    Write-Output "Warning ! Anonymous access is enable and authorized on your Active Directory ! Value = $ValuedsHeuristics"

}
