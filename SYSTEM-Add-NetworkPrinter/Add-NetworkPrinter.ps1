<#
.SYNOPSIS
	This script add one or several printer to the host (local). This script is a light alternative to the official cmdlet "Add-Printer" available since Windows 8.

.DESCRIPTION
    Specify a list of network printers that you want to add on the computer where the script run

.PARAMETER Name
    Name of one or several printers that you want to use

.PARAMETER DefaultPrinter
    If you want define a default printer, specify his name with this parameter.
    By default, the default printer isn't change

.PARAMETER DeleteAllNetworkPrinter
    Boolean to delete or not the others network printers installed on the computer
    By default, network printers aren't delete

.EXAMPLE
    .\Add-NetworkPrinter.ps1 -Name "\\ADDS-01.it-connect.local\Printer01" -DeleteAllNetworkPrinter $true
    Add the network printer "\\ADDS-01.it-connect.local\Printer01" and delete others network printers

    .\Add-NetworkPrinter.ps1 -Name "\\ADDS-01.it-connect.local\Printer01","\\ADDS-01.it-connect.local\Printer02" -DefaultPrinter "\\ADDS-01.it-connect.local\Printer02"
    Add two network printers ("\\ADDS-01.it-connect.local\Printer01" and "\\ADDS-01.it-connect.local\Printer02") and define "\\ADDS-01.it-connect.local\Printer02" as default printer

.INPUTS

.OUTPUTS
	
.NOTES
	NAME:	Add-NetworkPrinter.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel

	VERSION HISTORY:

	1.0 	2016.11.20
		    Initial Version

#>

PARAM(
    [Parameter(Mandatory = $true, HelpMessage = "You must specify at least one name for a printer")]
    $Name,

    [string]$DefaultPrinter,

    [boolean]$DeleteAllNetworkPrinter = $false
)

# If $DeleteAllNetworkPrinter is true, network printers are deleted
if($DeleteAllNetworkPrinter -eq $true){

    Get-WMIObject Win32_Printer | where{$_.Network -eq "true"} | foreach{ $_.delete() }

} # if($DeleteAllNetworkPrinter -eq $true)

#  Each network printer is installed
Foreach($Printer in $Name){

    if(!(Get-WMIObject Win32_Printer | where{$_.Name -eq $Printer})){

        $PrinterClass = [wmiclass]"win32_printer" 
        $PrinterClass.AddPrinterConnection($Printer) | Out-Null

    } # if(!(Get-WMIObject Win32_Printer | where{$_.Name -eq $Name}))

} # Foreach($Printer in $Name)

# Define the default printer if it's define by the user
if($DefaultPrinter -ne ""){

    (Get-WmiObject -ComputerName . -Class Win32_Printer | Where{ $_.Name -eq $DefaultPrinter }).SetDefaultPrinter()

} # if($DefaultPrinter -ne "")