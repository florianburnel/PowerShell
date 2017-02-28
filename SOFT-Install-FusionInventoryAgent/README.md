# Install-FusionInventoryAgent

This script do the installation of the Fusion Inventory Agent on local computer if isn't already installed. If the Fusion Inventory Agent is already installed, it will be updated if necessary. If the Fusion Inventory Agent is already up to date, nothing is do.
This script is provided AS IS

# Example

```
    .\Install-FusionInventoryAgent.ps1 -PathToSetup "C:\FusionInventory\" -SetupName "fusioninventory-agent_windows-x64_2.3.18.exe" -SetupOptions "/acceptlicense /runnow /execmode=service /add-firewall-exception /tag=MYTAG /S /no-ssl-check" -GLPIUri "https://glpi.domain.fr"

```

- PathToSetup : The path to the directory where is stored the setup (exe) to install on the local computer (without the setup name in the path)

- SetupName : The setup name of Fusion Inventory Agent that you want install. It must be on this form : fusioninventory-agent_windows-<architecture>_<version>.exe / Example : fusioninventory-agent_windows-x64_2.3.18.exe

- SetupOptions : Options to use for the installation (supported by Fusion Inventory) - Do not include the "/server" parameter HERE, use the "GLPIUri" parameter. Example : "/acceptlicense /runnow /execmode=service /add-firewall-exception /tag=YOUR-TAG /S /no-ssl-check"

- GLPIUri : This parameter contains the URI of the GLPI Server / Example : https://glpi.mydomain.fr/glpi/plugins/fusioninventory

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/SYSTEM-Add-NetworkPrinter/Images/Add-NetworkPrinter-Exemple.png)