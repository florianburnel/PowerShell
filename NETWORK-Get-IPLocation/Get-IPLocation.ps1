<#
.SYNOPSIS
	This script geolocation one or several IP address by a web request on the website geoipview.com

.DESCRIPTION
    Specify a list of IP address that you want to geolocation, and the function return the city and the country (origin) of the IP.

.PARAMETER IPToCheck
    The list of IP address, it's a required parameter.

.EXAMPLE
    .\Get-IPLocation -IPToCheck "4.4.4.4","8.8.8.8"
    Get the location of two IP address : 4.4.4.4 and 8.8.8.8

.INPUTS

.OUTPUTS
	
.NOTES
	NAME:	Get-IPLocation.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel

	VERSION HISTORY:

	1.0 	2017.01.17
		    Initial Version

#>

   param(
        [ipaddress[]]$IPToCheck
    )

    $Result = foreach($IPAddress in $IPToCheck){
        
        $WebResult = Invoke-WebRequest -Uri "http://fr.geoipview.com/?q=$IPAddress&x=7&y=8"
        
        $YourIP = (($WebResult.ParsedHtml.getElementsByName("yourip")[0].InnerText).Split(" "))[2]
        $YourCountry = ($WebResult.ParsedHtml.getElementsByTagName("td") | Where{ $_.className -eq "show2" })[0].InnerText
        $YourCity = ($WebResult.ParsedHtml.getElementsByTagName("td") | Where{ $_.className -eq "show2" })[1].InnerText

        $Hashtable = @{

            YourIP = $YourIP
            TargetIP = $IPAddress
            Country = $YourCountry
            City = if($YourCity -ne $null){
                         "$YourCity"
                   }else{
                         "Unknown" 
                   } # if($YourCity -ne $null)
            
            GoogleMaps = if($YourCity -ne $null){
                               "https://www.google.fr/maps/place/$($YourCity.Replace(' ',''))"
                         }else{
                               "https://www.google.fr/maps/place/$($YourCountry.Replace(' ',''))" 
                         } # if($YourCity -ne $null)
        }
        
        # Create a PowerShell object with the hashtable
        New-Object -TypeName PSObject -Property $Hashtable | Select-Object -Property YourIP, TargetIP, Country, City, GoogleMaps

    } # foreach($IPAddress in $IPToCheck)