<#

    .SYNOPSYS - Déployer les prérequis de BlockRansomwares

#>
# 1 - PowerShell V3 requis au minimum
$powershellVer = $PSVersionTable.PSVersion.Major

if ($powershellVer -le 2)
{    
    Write-Host "Version PowerShell (v3 minimum) : ERREUR - PowerShell $($PSVersionTable.PSVersion.ToString())" -ForegroundColor Red
}else{
    Write-Host "Version PowerShell (v3 minimum) : OK - PowerShell $($PSVersionTable.PSVersion.ToString())" -ForegroundColor Green
}

# 2 - Fonctionnalité FSRM
if((Get-WindowsFeature -Name "FS-Resource-Manager").InstallState -eq "Available"){
    Try{
        
        Install-WindowsFeature –Name FS-Resource-Manager –IncludeManagementTools -ErrorAction Stop
        Write-Host "Fonctionnalité FSRM : OK - Installée à l'instant" -ForegroundColor Green
    }Catch{

        Write-Host "Fonctionnalité FSRM : ERREUR - Installation impossible ($($_.Exception.Message))." -ForegroundColor Red
    }
}elseif((Get-WindowsFeature -Name "FS-Resource-Manager").InstallState -eq "Installed"){

    Write-Host "Fonctionnalité FSRM : OK - Déjà présente" -ForegroundColor Green
}
