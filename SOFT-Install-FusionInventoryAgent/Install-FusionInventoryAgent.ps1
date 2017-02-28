<#
.SYNOPSIS
	Install or update the Fusion Inventory Agent on local computer, if it's necessary

.DESCRIPTION
    This script do the installation of the Fusion Inventory Agent on local computer if isn't already installed.
    If the Fusion Inventory Agent is already installed, it will be updated if necessary.
    If the Fusion Inventory Agent is already up to date, nothing is do.

.PARAMETER PathToSetup
    The path to the directory where is stored the setup (exe) to install on the local computer (without the setup name in the path)

.PARAMETER SetupName
    The setup name of Fusion Inventory Agent that you want install. It must be on this form : fusioninventory-agent_windows-<architecture>_<version>.exe
    Example : fusioninventory-agent_windows-x64_2.3.18.exe

.PARAMETER SetupOptions
    Options to use for the installation (supported by Fusion Inventory) - Do not include the "/server" parameter HERE, use the "GLPIUri" parameter.
    Example : "/acceptlicense /runnow /execmode=service /add-firewall-exception /tag=YOUR-TAG /S /no-ssl-check"

.PARAMETER GLPIUri
    This parameter contains the URI of the GLPI Server
    Example : https://glpi.mydomain.fr/glpi/plugins/fusioninventory

.EXAMPLE
    Install-FusionInventoryAgent.ps1 -PathToSetup "C:\FusionInventory\" -SetupName "fusioninventory-agent_windows-x64_2.3.18.exe" -SetupOptions "/acceptlicense /runnow /execmode=service /add-firewall-exception /tag=MYTAG /S /no-ssl-check" -GLPIUri "https://glpi.domain.fr"
    
.INPUTS

.OUTPUTS
	
.NOTES
	NAME:	Install-FusionInventoryAgent.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel

	VERSION HISTORY:

	1.0 	2017.01.17
		    Initial Version

#>

### Parameters
    param(
        [parameter(Mandatory=$true)][ValidateScript({Test-Path $_ })][string]$PathToSetup,
        [parameter(Mandatory=$true)][ValidatePattern("^fusioninventory-agent_windows-x[6-8][4-6]_[0-9].[0-9].\d{1,2}.exe$")][string]$SetupName,
        [parameter(Mandatory=$true)][string]$SetupOptions,
        [parameter(Mandatory=$true)][string]$GLPIUri
    )

### Function to define the address of the GLPI Server in the registry
    Function DefineGLPIServer{

        param(
            [string]$SetupName,
            [string]$GLPIUri,
            [string]$SetupArchitecture,
            [string]$ComputerArchitecture
        )

        # Before change the "server" parameter, wait the end of the installation process
        Wait-Process -Name $SetupName.Replace(".exe","")

        if((Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\FusionInventory-Agent\" -Name "Server" -ErrorAction SilentlyContinue) -and ($SetupArchitecture -eq "x86") -and ($ComputerArchitecture -eq "x64")){
                    
             # Modify in the registry the GLPI server URI
             Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\FusionInventory-Agent\" -Name "Server" -Value $GLPIUri

             # Restart "FusionInventory Agent" Service
             Restart-Service "FusionInventory Agent"

        }elseif((Get-ItemProperty -Path "HKLM:\SOFTWARE\FusionInventory-Agent\" -Name "Server" -ErrorAction SilentlyContinue) -and ($SetupArchitecture -eq "x86") -and ($ComputerArchitecture -eq "x86") -or ($SetupArchitecture -eq "x64") -and ($ComputerArchitecture -eq "x64")){
                    
             # Modify in the registry the GLPI server URI
             Set-ItemProperty -Path "HKLM:\SOFTWARE\FusionInventory-Agent\" -Name "Server" -Value $GLPIUri

             # Restart "FusionInventory Agent" Service
             Restart-Service "FusionInventory Agent"

        } # if(Get-ItemProperty -Path "HKLM:\SOFTWARE\FusionInventory-Agent\" -Name "Server" )

    } # function DefineGLPIServer

### Function : Determine if a version is already installed
    Function AlreadyInstalledOrNot{

        param(
            [string]$ComputerArchitecture
        )

        # For 32 bits operating system
        if($ComputerArchitecture -eq "x86"){

            if((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\" -ErrorAction SilentlyContinue).DisplayVersion){
                
                [version]$CurrentVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\" -ErrorAction SilentlyContinue).DisplayVersion

            }elseif((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\" -ErrorAction SilentlyContinue).DisplayVersion){

                [version]$CurrentVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\" -ErrorAction SilentlyContinue).DisplayVersion

            }else{

                [version]$CurrentVersion = "0.0"

            } # if((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\" -ErrorAction SilentlyContinue).DisplayVersion)
        
        # For 64 bits operating system
        }elseif($ComputerArchitecture -eq "x64"){

            if((Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\" -ErrorAction SilentlyContinue).DisplayVersion){
                
                [version]$CurrentVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\" -ErrorAction SilentlyContinue).DisplayVersion

            }elseif((Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\" -ErrorAction SilentlyContinue).DisplayVersion){

                [version]$CurrentVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\" -ErrorAction SilentlyContinue).DisplayVersion

            }elseif((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\" -ErrorAction SilentlyContinue).DisplayVersion){

                [version]$CurrentVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\" -ErrorAction SilentlyContinue).DisplayVersion

            }else{

                [version]$CurrentVersion = "0.0"

            } # if((Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\" -ErrorAction SilentlyContinue).DisplayVersion)                        
            
        } # if($ComputerArchitecture -eq "x86")

        return $CurrentVersion

    } # Function AlreadyInstalledOrNot

### Determine Operating System Architecture
    if((Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq "64 bits"){

        $ComputerArchitecture = "x64"

    }elseif((Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq "32 bits"){

        $ComputerArchitecture = "x86"

    } # if((Get-WmiObject Win32_OperatingSystem).OSArchitecture -eq "64 bits")

### Determine Fusion Inventory Setup Architecture
    if($SetupName -match "x64"){

        $SetupArchitecture = "x64"

    }elseif($SetupName -match "x86"){

        $SetupArchitecture = "x86"

    } # if($SetupName -match "x64")

### Determine Fusion Inventory Setup Version
    [version]$SetupVersion = (($SetupName).Split("_"))[2].Replace(".exe","")

    # Compare the setup architecture with the operating system architecture
    if(($ComputerArchitecture -eq "x86") -and ($SetupArchitecture -eq "x64")){
    
        Write-Output "This version of Fusion Inventory isn't compatible with this computer !"
    
    }else{

        # Determine the full path to the setup
        $FullPathToSetup = $PathToSetup + "\" + $SetupName
        $FullPathToSetup = $FullPathToSetup.Replace("\\$SetupName","\$SetupName")
        
        # Check if the Fusion Inventory Agent is already installed or not (get the actual version)
        [version]$CurrentVersion = AlreadyInstalledOrNot -ComputerArchitecture $ComputerArchitecture
        
        # if $CurrentVersion is empty, we can install the Fusion Inventory agent
        if($CurrentVersion -eq "0.0"){

            Write-Output "Installation of Fusion Inventory Agent $SetupVersion necessary because it is not installed..."
            Write-Output "Path to the setup : $FullPathToSetup"

            if(Get-Service "FusionInventory Agent" -ErrorAction SilentlyContinue){ Stop-Service "FusionInventory Agent" }

            # Start the installation of the Fusion Inventory Agent, with your setup and your options
            Invoke-Expression "& $FullPathToSetup $SetupOptions"

            # Define the server URL
            DefineGLPIServer -SetupName $SetupName -GLPIUri $GLPIUri -SetupArchitecture $SetupArchitecture -ComputerArchitecture $ComputerArchitecture

        }elseif($SetupVersion -gt $CurrentVersion){

            Write-Output "Installation of Fusion Inventory Agent necessary because it is out of date... (Setup $SetupVersion VS Actual $CurrentVersion)"

            Write-Output "Path to the setup : $FullPathToSetup"

            if(Get-Service "FusionInventory Agent" -ErrorAction SilentlyContinue){ Stop-Service "FusionInventory Agent" }

            # Start the installation of the Fusion Inventory Agent, with your setup and your options
            Invoke-Expression "& $FullPathToSetup $SetupOptions"

            # Define the server URL
            DefineGLPIServer -SetupName $SetupName -GLPIUri $GLPIUri -SetupArchitecture $SetupArchitecture -ComputerArchitecture $ComputerArchitecture

        }elseif($SetupVersion -eq $CurrentVersion){

            Write-Output "The actual version is equal to the setup version (Setup $SetupVersion VS Actual $CurrentVersion)"

        }elseif($SetupVersion -lt $CurrentVersion){

            Write-Output "The actual version is more recent that the setup version (Setup $SetupVersion VS Actual $CurrentVersion)"

        } # if($CurrentVersion -eq "0.0")

    } # if(($ComputerArchitecture -eq "x86") -and ($SetupArchitecture -eq "x64"))
 