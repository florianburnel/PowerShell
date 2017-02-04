<#
.SYNOPSIS
	Download files recursively with BITS with the same arborescence.

.DESCRIPTION
    This script download files recursively using BITS transfer method. 
    It recreate the arborescence of the source in the destination folder, and download each file at the same place that in the source.

.PARAMETER Source
    The path to the source folder, all files in his subfolders will be copied. PLEASE, DO NOT INCLUDE A BACKSLASH AT THE END OF THE PATH

.PARAMETER Destination
    The path to the destination folder, where you want to store downloaded files. PLEASE, DO NOT INCLUDE A BACKSLASH AT THE END OF THE PATH

.EXAMPLE
    .\Start-BitsDownloadRecursive.ps1 -Source "\\192.168.1.150\Download\BITS\" -Dest "C:\temp\BITS"
    
.INPUTS

.OUTPUTS
	
.NOTES
	NAME:	Start-BitsDownloadRecursive.ps1
	AUTHOR:	Florian Burnel
	EMAIL:	florian.burnel@it-connect.fr
	WWW:	www.it-connect.fr
	Twitter:@FlorianBurnel

	VERSION HISTORY:

	1.0 	2017.02.02
		    Initial Version

    TODO
    * Include a parameter for credentials
    * Improve control over transfers
    * Add possibility to exclude folders

#>

### Parameters
param(
    [parameter(Mandatory=$true)][ValidateScript({Test-Path $_ })][String]$Source,
    [parameter(Mandatory=$true)][ValidateScript({Test-Path $_ })][String]$Dest
)

# Import module BitsTransfer
Import-Module BitsTransfer -ErrorAction SilentlyContinue -ErrorVariable ModuleState

# Continue only if the module is correctly imported
if(!($ModuleState)){

    Get-ChildItem $Source -Recurse -Directory | foreach{
        
        # Start the download of files which are in the root of the source
        if((Get-BitsTransfer -Name "Root-Source" -ErrorAction SilentlyContinue).Count -eq 0){

            Start-BitsTransfer -Asynchronous -Source "$Source\*.*" -Destination $Dest -DisplayName "Root-Source"

        } # if((Get-BitsTransfer -Name "Root-Source" -ErrorAction SilentlyContinue).Count -eq 0)

        # Path to the child item (directory)
        $DestChild = ($_.FullName).Replace($Source,"")
    
        # If the directory in the destination is already created, start the BITS transfer, else it will be create before start the job.
        if(Test-Path "$Dest\$DestChild\"){

            Start-BitsTransfer -Asynchronous -Source "$($_.FullName)\*.*" -Destination "$Dest\$DestChild\" -DisplayName $_.Name

        }else{

            New-Item -ItemType Directory -Path "$Dest\$DestChild" -ErrorVariable FolderCreation
        
            if(!($FolderCreation)){
            
                Start-BitsTransfer -Asynchronous -Source "$($_.FullName)\*.*" -Destination "$Dest\$DestChild\" -DisplayName $_.Name
            
            }else{

                Write-Host "ERROR ! Impossible to create the destination folder ($DestChild) !" -ForegroundColor Red
            
            } # if(!($FolderCreation))

        } # if(Test-Path "$Dest\$DestChild\")
    }

    # Wait during the BITS transfer before to complete it
    While( ((Get-BitsTransfer).JobState -eq "Transferring") -or ((Get-BitsTransfer).JobState -eq "Connecting") ){

    Start-Sleep -Seconds 3

    }

    # Complete all the BITS transfer
    Get-BitsTransfer | Complete-BitsTransfer

    # Check that the source and the destination are the same number of elements
    if((Get-ChildItem $Source -Recurse).Count -eq (Get-ChildItem $Dest -Recurse).Count){

        Write-Host "Transfer complete ! All elements are transferred !" -ForegroundColor Green

    }else{

        Write-Host "ERROR ! One or several elements aren't transferred !" -ForegroundColor Red

    } # if((Get-ChildItem $Source -Recurse).Count -eq (Get-ChildItem $Dest -Recurse).Count)

}else{

    Write-Host "ERROR ! Impossible to load the module BitsTransfer" -ForegroundColor Red

} # if(!($ModuleState))
