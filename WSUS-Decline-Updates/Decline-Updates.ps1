<#
.Synopsis 
   Sample script to decline superseded updates from WSUS, and run WSUS cleanup if any changes are made  

.DESCRIPTION 
   Declines updates from WSUS if update meets any of the following:
        - is superseded
        - is expired (as defined by Microsoft)
        - is for x86 or itanium operating systems
        - is for Windows XP
        - is a language pack
        - is for old versions of Internet Explorer (versions 7,8,9)
        - contains some country names for country specific updates not filtered by WSUS language filters.
        - is a beta update
        - is for an embedded operating system

    If an update is released for multiple operating systems, and one or more of the above criteria are met, the versions of the update that do not meet the above will not be declined by this script

.EXAMPLE 
   .\Decline-Updates -WSUSServer WSUSServer.Company.com -WSUSPort 8530

# Last updated 13 July 2016
 
# Author 
Nick Eales, Microsoft
#>


Param(    
    [Parameter(Mandatory=$false, 
    ValueFromPipeline=$true, 
    ValueFromPipelineByPropertyName=$true, 
    ValueFromRemainingArguments=$false, 
    Position=0)] 
    [string]$WSUSServer = "Localhost", #default to localhost
    [int]$WSUSPort=8530,
    [switch]$reportonly
    )

Function Decline-Updates{
    Param(
        [string]$WsusServer,
        [int]$WSUSPort,
        [switch]$ReportOnly
    )
    write-host "Connecting to WSUS Server $WSUSServer and getting list of updates"
    $Wsus = Get-WSUSserver -Name $WSUSServer -PortNumber $WSUSPort
    if($WSUS -eq $Null){
        write-error "unable to contact WSUSServer $WSUSServer"
    }else{
        $Updates = $wsus.GetUpdates()
        write-host "$(($Updates | where {$_.IsDeclined -eq $false} | measure).Count) Updates before cleanup"
        $updatesToDecline = $updates | where {$_.IsDeclined -eq $false -and (
        $_.IsSuperseded -eq $true -or   #remove superseded updates
        $_.PublicationState -eq "Expired" -or #remove updates that have been pulled by Microsoft
        $_.LegacyName -match "ia64" -or #remove updates for itanium computers (1/2)
        $_.LegacyName -match "x86" -or  #remove updates for 32-bit computers
        $_.LegacyName -match "XP" -or   #remove Windows XP updates (1/2)
        $_.producttitles -match "XP" -or #remove Windows XP updates (1/2)
        $_.Title -match "Itanium" -or   #remove updates for itanium computers (2/2)
        $_.Title -match "language\s" -or  #remove langauge packs
        $_.title -match "Internet Explorer 7" -or #remove updates for old versions of IE
        $_.title -match "Internet Explorer 8" -or 
        $_.title -match "Internet Explorer 9" -or 
        $_.title -match "Japanese" -or #some non-english updates are not filtered by WSUS language filtering
        $_.title -match "Korean" -or   
        $_.title -match "Taiwan" -or  
        $_.Title -match "Beta" -or     #Beta products and beta updates
        $_.title -match "Embedded"     #Embedded version of Windows
        )}
        
        write-host "$(($updatesToDecline | measure).Count) Updates to decline"
        $changemade = $false        
        if($reportonly){
            write-host "ReportOnly was set to true, so not making any changes"
        }else{
            $changemade = $true
            $updatesToDecline | %{$_.Decline()}
        }

        #Decline updates released more then 3 months prior to the release of an included service pack
        # - service packs updates don't appear to contain the supersedance information.
        Foreach($SP in $($updates | where title -match "^Windows Server \d{4} .* Service Pack \d")){
            if(($SP.ProductTitles |measure ).count -eq 1){
                $updatesToDecline = $updates | where {$_.IsDeclined -eq $false -and $_.ProductTitles -contains $SP.ProductTitles -and $_.CreationDate -lt $SP.CreationDate.Addmonths(-3)}
                if($updatesToDecline -ne $null){
                    write-host "$(($updatesToDecline | measure).Count) Updates to decline (superseded by $($SP.Title))"
                    if(-not $reportonly){
                        $changemade = $true
                        $updatesToDecline | %{$_.Decline()}
                    }
                }
            }
        }
        
        #if changes were made, run a WSUS cleanup to recover disk space
        if($changemade -eq $true -and $reportonly -eq $false){
            $Updates = $wsus.GetUpdates()
            write-host "$(($Updates | where {$_.IsDeclined -eq $false} | measure).Count) Updates remaining, running WSUS cleanup"
            Invoke-WsusServerCleanup -updateServer $WSUS -CleanupObsoleteComputers -CleanupUnneededContentFiles -CleanupObsoleteUpdates -CompressUpdates -DeclineExpiredUpdates -DeclineSupersededUpdates
        }

    }
}

Decline-Updates -WSUSServer $WSUSServer -WSUSPort $WSUSPort -reportonly:$reportonly