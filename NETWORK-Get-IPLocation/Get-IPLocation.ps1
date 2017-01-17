function Get-IPLocation{

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

$Result

}