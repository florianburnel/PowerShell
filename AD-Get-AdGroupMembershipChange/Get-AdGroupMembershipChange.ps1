#requires -Module ActiveDirectory
 
<#
        .SYNOPSIS
        
        This script queries multiple Active Directory groups for new members in a domain.  It records group membership
        in a CSV file in the same location as the script is located. On the script's initial run it will simply record
        all members of all groups into this CSV file.  On subsequent runs it will query each group's member list and compare
        that list to what's in the CSV file.  If any differences are found (added or removed) the script will update the
        CSV file to reflect current memberships and notify an administrator of which members were either added or removed.
        
        .NOTES

	    NAME:	Get-AdGroupMembershipChange.ps1
	    AUTHOR:	Florian Burnel (from the original script of Adam D. Bertram)
	    EMAIL:	florian.burnel@it-connect.fr
	    WWW:	www.it-connect.fr
	    TWITTER: @FlorianBurnel
        REFERENCES: Adam D. Bertram
        LINK: https://gallery.technet.microsoft.com/scriptcenter/Detect-Changes-to-AD-Group-012c3ffa
        
        .EXAMPLE
        
        PS> .\Get-AdGroupMembershipChange.ps1 -Email "florian.burnel@mydomain.fr" -LogFilePath "C:\Logs\Audit_Get-AdGroupMembershipChange\Audit_log.csv" -GroupFilePath "C:\Logs\Audit_Get-AdGroupMembershipChange\Audit_list_reference.csv" -Group "Administrateurs de l’entreprise", "Admins du domaine"
   
        This example will query group memberships of the "Administrateurs de l’entreprise", "Admins du domaine" groups and email
        florian.burnel@mydomain.fr when a member is either added or removed from any of these groups. Moreover, there is the logfile "Audit_log.csv".
 
        .PARAMETER Group
        One or more group names to monitor for membership changes

        .PARAMETER Email
        The email address of the administrator that would like to get notified of group changes.
        The notification contain an HTML report.

        .PARAMETER LogFilePath
        This file logs the different actions in monitored groups

        .PARAMETER GroupFilePath
        This is the file that will record the most recent group membership and will be used to compare current to most recent.
        It's the reference file.

        .PARAMETER SendByEmail
        Boolean, if it's true notification will be send by email, otherwise the result will be only export in HTML or display in the console (it depends on ExportAsHTML)

        .PARAMETER ExportAsHTML
        Path to the file for the html report
#>
[CmdletBinding(SupportsShouldProcess)]
[OutputType('System.Management.Automation.PSCustomObject')]

param (
    [Parameter(Mandatory)]
    [string[]]$Group,
    [Parameter()]
    [ValidatePattern('\b[A-Z0-9._%+-]+@(?:[A-Z0-9-]+\.)+[A-Z]{2,4}\b')]
    [string]$Email = 'florian.burnel@mydomain.fr',
    [Parameter()]
    [string]$LogFilePath = "$PsScriptRoot\AdGroupMembershiplogfile.csv",
    [string]$GroupFilePath = "$PsScriptRoot\AdGroupMembershipChange.csv",
    [Parameter(Mandatory)][string]$ExportASHTML = "$PsScriptRoot\AdGroupMembershipChange.html",
    [boolean]$SendByEmail = $false
)
 
begin {
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

    Set-strictMode -off
    
    # Write log in the logfile
    function Write-Log {
        <#
                .SYNOPSIS
                This function creates or appends a line to a log file
 
                .DESCRIPTION
                This function writes a log line to a log file
                .PARAMETER  Message
                The message parameter is the log message you'd like to record to the log file
                .PARAMETER  LogLevel
                The logging level is the severity rating for the message you're recording.
                You have 3 severity levels available; 1, 2 and 3 from informational messages
                for FYI to critical messages. This defaults to 1.
 
                .EXAMPLE
                PS C:\> Write-Log -Message 'Value1' -LogLevel 'Value2'
           
                This example shows how to call the Write-Log function with named parameters.
        #>
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)]
            [string]$Message,
            [Parameter()]
            [ValidateSet(1, 2, 3)]
            [int]$LogLevel = 1
        )
       
        try {
            $TimeGenerated = "$(Get-Date -Format HH:mm:ss).$((Get-Date).Millisecond)+000"
            ## Build the line which will be recorded to the log file
            $Line = '{2} {1}: {0}'
            $LineFormat = $Message, $TimeGenerated, (Get-Date -Format MM-dd-yyyy)
            $Line = $Line -f $LineFormat
           
            Add-Content -Value $Line -Path $LogFilePath
        } catch {
            Write-Error $_.Exception.Message
        }
    }
	
	function Add-GroupMemberToLogFile ($GroupName,[string[]]$Member) {
        foreach ($m in $Member) {
            [pscustomobject]@{'Group' = $GroupName; 'Member' = $m} | Export-Csv -Path $GroupFilePath -Append -NoTypeInformation
        }  
    }
   
    function Get-GroupMemberFromLogFile ([string]$GroupName) {
        (Import-Csv -Path $GroupFilePath | Where-Object { $_.Group -eq $GroupName }).Member
    }
   
    function Send-ChangeNotification {

        # Get the log content
        $ReportContent = Get-Content $ExportASHTML | Out-String
        
        # Parameters
        $Params = @{
            'From' = 'Active Directory Administrator <audit-active-directory@mydomain.fr>'
            'To' = $Email
            'Subject' = 'Active Directory - Audit - Group Change'
            'SmtpServer' = 'smtp.mydomain.fr'
            'Body' = $ReportContent
            'BodyAsHtml' = $true
            'Encoding' = [System.Text.Encoding]::UTF8
        }

        # Send the message
        Send-MailMessage @Params
    
    } # function Send-ChangeNotification

    # Initialize counters
    [int]$script:CountNothing = 0
    [int]$script:CountAdded = 0
    [int]$script:CountRemoved = 0

}
 
process {
    
    try {
        
        if (-not (Test-Path -Path $GroupFilePath -PathType Leaf)) {
			Write-Log -Message "The log file [$GroupFilePath] does not exist yet. Creating file."
			New-Item -path $GroupFilePath -type "file" }
		
        Write-Log -Message 'Querying Active directory domain for group memberships...'
        
        # Get members of each group of your list
        $AuditADResult = foreach ($g in $Group) {
            
            Write-Log -Message "Querying the [$g] group for members..."
            $CurrentMembers = (get-adgroupmember -Identity $g).DistinguishedName
            
            if (-not $CurrentMembers) {
                
                Write-Log -Message "No members found in the [$g] group."
            
            } else {
                
                Write-Log -Message "Found [$($CurrentMembers.Count)] members in the [$g] group"
                $PreviousMembers = Get-GroupMemberFromLogFile -GroupName $g
				
                if (-not $PreviousMembers) {
                
                    Write-Log -Message "[$g] not found in log file. Dumping all members into it..."
                    Add-GroupMemberToLogFile -GroupName $g -Member $CurrentMembers
					$PreviousMembers = Get-GroupMemberFromLogFile -GroupName $g
                
                } if ($PreviousMembers) {
                    
                    Write-Log -Message "Reading previous [$g] group members..." 
					$PreviousMembers = Get-GroupMemberFromLogFile -GroupName $g
                    $ComparedMembers = Compare-Object -ReferenceObject $PreviousMembers -DifferenceObject $CurrentMembers 
                    
                    if (-not $ComparedMembers) {
                        
                        Write-Log "No differences found in group $g"
                        
                        # Create a PS Custom Object with all informations
                        [PSCustomObject] @{
                            "MonitoringGroup" = $g ;
                            "Member" = "-" ;
                            "Action" = "Nothing"
                        }

                        $script:CountNothing++

                    } else {
                        
                        $RemovedMembers = $ComparedMembers | Where-Object {$_.SideIndicator -eq '<=' } | foreach {"$($_.InputObject)"}
                        
                        if (-not $RemovedMembers) {
                        
                            Write-Log -Message 'No members have been removed since last check'
                                                     
                        } else {
                        
                            Write-Log -Message "Found [$($RemovedMembers.Count)] members that have been removed since last check"
                            Write-Log -Message "Emailed change notification to $Email"

                            ## Remove the members from the CSV file to keep the file current
                            (Import-Csv -Path $GroupFilePath | Where-Object {$RemovedMembers -notcontains $_.Member}) | Export-Csv -Path $GroupFilePath -NoTypeInformation
                        
                            ForEach($Member in $RemovedMembers){
                                 [PSCustomObject] @{
                                     "MonitoringGroup" = $g ;
                                     "Member" = $Member ;
                                     "Action" = "Removed"
                                 }
                                 
                                 $script:CountRemoved++                        
                            }
                        } # if (-not $RemovedMembers)
                         
                         $AddedMembers = $ComparedMembers | Where-Object {$_.SideIndicator -eq '=>' } | foreach {"$($_.InputObject)"}
                         
                         if (-not $AddedMembers) {
                         
                             Write-Log -Message 'No members have been removed since last check'
                         
                         } else {

                             Write-Log -Message "Found [$($AddedMembers.Count)] members that have been added since last check"
                             Write-Log -Message "Emailed change notification to $Email"

                             ## Add the members from the CSV file to keep the file current
                             $AddedMembers | foreach {[pscustomobject]@{'Group' = $g; 'Member' = $_}} | Export-Csv -Path $GroupFilePath -Append -NoTypeInformation
                        
                             # Create a PS Custom Object with all informations
                            ForEach($Member in $AddedMembers){                         
                                 
                                 [PSCustomObject] @{
                                     "MonitoringGroup" = $g ;
                                     "Member" = $Member ;
                                     "Action" = "Added"
                                 }

                                 $script:CountAdded++
                            }

                         } # if (-not $AddedMembers)
                       
                    }
                
				}
            } # if (-not $CurrentMembers)
 
        }

    # Generate a HTML report if the parameter ExportAsHTML contain a path
    if(-not $ExportASHTML){

        $AuditADResult | Format-Table -AutoSize

    }else{

        # CSS style for the HTML page
        $CSSInHeader = "<style>th{background-color : #000071; color : #fff; padding: 10px}
                               body{padding: 5px; font-family: Calibri;}
                               td{ padding: 10px}
                               table tr:nth-child(even) { background: #fff; }
                               table tr:nth-child(odd) { background: #D8D8D8; }
                               div.Counter { background-color: #EEEEEE; width: 350px; padding: 10px; text-align: center; }
                        </style>"
        
        # Date of the day
        $Date = Get-Date -Format "dd/MM/yyyy"

        # Exclude empty line(s)
        $AuditADResult = $AuditADResult | Where{ $_.MonitoringGroup -ne $null }

        # Export the objects collection $AuditADResult in the HTML format
        $AuditADResult | ConvertTo-Html -Head $CSSInHeader -PreContent "<h2 style='border-bottom: 2px solid; padding-bottom: 15px;'>Active Directory - Audit - Group Change - $Date</h2><div class='Counter'><strong><span style='color:#000'>Nothing : $CountNothing</span>&nbsp;-&nbsp;<span style='color:#008000'>Added : $CountAdded</span>&nbsp;-&nbsp;<span style='color:#F70000'>Removed : $CountRemoved</span></strong></div></br>" -PostContent "</br><i>Rapport généré le $(Get-Date -Format "dd/MM/yyyy") sur le serveur $env:COMPUTERNAME</i>" | 
                       Foreach{ 
                
                        if( $_ -match "<td>Added</td>" ){

                            $_ -replace "<tr>" , "<tr style='background-color : #99CC00;'>"

                        }elseif($_ -match "<td>Removed</td>"){

                            $_ -replace "<tr>" , "<tr style='background-color : #FF7777;'>"

                        }elseif($_ -match "<td>Nothing</td>"){

                            $_ -replace "<tr>" , "<tr style='background-color : #E2E2E2;'>"

                        }else{

                            $_
                        }
               
                       } | Out-File $ExportASHTML

        if($SendByEmail -eq $true){
        
            Send-ChangeNotification
        
        }    

    } # if($ExportAsHTML -eq $false)
 
    } catch {
        Write-Error "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
    }
}