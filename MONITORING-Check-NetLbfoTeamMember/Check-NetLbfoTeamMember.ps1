<#
.SYNOPSIS
	Check status of teaming members. All teams of a local server.

.DESCRIPTION

.PARAMETER 

.EXAMPLE

.INPUTS

.OUTPUTS
	
.NOTES
	NAME:	Check-NetLbfoTeamMember.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel

	VERSION HISTORY:

	1.0 	2021.01.22
		    Initial Version

#>
# Initial state
$ExitCode = 0

# Get the status
$LbfoTeamMemberOutput = Get-NetLbfoTeamMember | Select-Object Name,FailureReason,Team
$LbfoTeamMemberCount = (Get-NetLbfoTeamMember).Count

# Normal state : AdministrativeDecision / NoFailure
Foreach($Member in $LbfoTeamMemberOutput){

    if(!(($Member.FailureReason -eq "NoFailure") -or ($Member.FailureReason -eq "AdministrativeDecision"))){

        $ExitCode = 2
        Write-Output "CRITICAL: Member $($Member.Name) of the team $($Member.Team) state is $($Member.FailureReason)"

    }
}

# Evaluate final exit code result for all passed checks.
if ($ExitCode -eq 0) { Write-Output "OK: Members ($LbfoTeamMemberCount) of all LBFO teams are OK" }

exit $ExitCode