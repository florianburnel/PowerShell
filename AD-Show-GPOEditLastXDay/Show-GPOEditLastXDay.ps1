<#
.SYNOPSIS
	What are the GPOs modified in the last X days ?

.DESCRIPTION
    The script detects which GPOs are modified in the last X days, based on the current date at the execution time

.PARAMETER DomainName
    This parameter must contain the DNS name of your domain Active Directory
    Example : it-connect.local

.PARAMETER LastXDays
    Number of days to consider for detect a change in one of the GPO
    Example : 7 (for 7 days)

.EXAMPLE
    .\Show-GPOEditLastXDay.ps1 -DomainName "it-connect.local" -LastXDays 7
    
.INPUTS

.OUTPUTS
	
.NOTES
	NAME:	Show-GPOEditLastXDay.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel

	VERSION HISTORY:

	1.0 	2017.07.24
		    Initial Version

#>


function Show-GPOEditLastXDay{
    
    # Parameters
    param(
        [parameter(Mandatory=$true)][string]$DomainName,
        [parameter(Mandatory=$true)][int]$LastXDays
    )

    # Create GPMgmt COM Object
    $GPM = New-Object -ComObject GPMgmt.GPM

    try{

        # Link the domain
        $GPMDomain =$GPM.GetDomain("$DomainName", "", $GPMConstants.UseAnyDC)
    
        # Search Criteria, empty
        $GPMSearchCriteria = $GPM.CreateSearchCriteria()
    
        # Search all GPO in this domain
        $GPMAllGpos = $GPMDomain.SearchGPOs($GPMSearchCriteria)

        # Counter init
        $Counter = 0

        # Foreach GPO... Check if the GPO has been modified in the last X days
        foreach ($GPO in $GPMAllGpos) { 

            if ($GPO.ModificationTime -ge (Get-Date).AddDays(-$LastXDays)) {

                # Create a PS Custom Object with the name of the GPO and his modification time
                [PSCustomObject] @{
                    "GPOName" = $GPO.DisplayName ;
                    "GPOModificationTime" = $GPO.ModificationTime
                }

                $Counter++
            } 

        } # foreach ($GPO in $GPMAllGpos)
        
        if($Counter -eq 0){
            Write-Output "0 GPO modified in the last $LastXDays day(s)"
        } # if($Counter -eq 0)

    }catch{

        Write-Output "ERROR ! Impossible to get the list of edited GPO, it's possible that the domain name is incorrect"
    
    } # Try / Catch
}