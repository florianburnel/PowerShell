# New-NanoServerVM for Hyper-V

New-NanoServerVM create a VHDX with the Nano Server image, add a new VM on the Hyper-V host and attach the VHDX to this VM

# Example

```
.\New-NanoServerVM.ps1 -ISOPath "V:\ISO\WS2016.ISO" -NanoModulePath "V:\NANO" -VHDXPath "V:\VM\VHDX" -VMName "NanoServer-02" -password (ConvertTo-SecureString -AsPlainText -Force "P@ssWoRd") -VMvSwitch "LAN" -VMPowerOn $false
```

Or

```
.\New-NanoServerVM.ps1 -ISOPath "V:\ISO\WS2016.ISO" -NanoModulePath "V:\NANO" -VHDXPath "V:\VM\VHDX" -VMName "NanoServer-03" -password (ConvertTo-SecureString -AsPlainText -Force "P@ssWoRd") -VMvSwitch "LAN" -VMPowerOn $false -VMPackage "Microsoft-NanoServer-DSC-Package,Microsoft-NanoServer-DNS-Package"
```

- ISOPath : The path to the ISO file of Windows Server 2016, to get NanoServerGenerator

- NanoModulePath : The destination path to copy the NanoServerGenerator folder which contains the module NanoServerImageGenerator

- VHDXPath : The path where you want to store the VHDX file for the new NanoServer VM

- VMName : Name of the VM on Hyper-V

- Password : Password of the "Adminisitrator" account in Nano Server, for this new VM

- VMvSwitch : Name of the virtual network (vSwitch) that you want to use to connect this VM on the network. It must be already exist

- VMPowerOn : Boolean to define if you want that the VM start or not after the creation. By default, the VM will start

- VMPackage : List of one or multiple package that you want to include in the NanoServer image, such as "Microsoft-NanoServer-DSC-Package" or "Microsoft-NanoServer-DNS-Package". You must separate the package name by comma, for example : "Microsoft-NanoServer-DSC-Package,Microsoft-NanoServer-DNS-Package"

![alt tag](https://github.com/florianburnel/PowerShell/blob/master/HYPER-V-New-NanoServerVM/Images/New-NanoServerImage-Example.png?raw=true)