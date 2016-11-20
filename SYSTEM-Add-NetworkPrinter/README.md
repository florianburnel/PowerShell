# Add-NetworkPrinter

Add-NetworkPrinter add one or several printer to the host (local). Specify a list of network printers that you want to add.

# Example

```
    .\Add-NetworkPrinter.ps1 -Name "\\ADDS-01.it-connect.local\Printer01" -DeleteAllNetworkPrinter $true
```

Or

```
.\Add-NetworkPrinter.ps1 -Name "\\ADDS-01.it-connect.local\Printer01","\\ADDS-01.it-connect.local\Printer02" -DefaultPrinter "\\ADDS-01.it-connect.local\Printer02"
```

- Name : Name of one or several network printers that you want to use

- DefaultPrinter : If you want define a default printer, specify his name with this parameter. By default, the default printer isn't change.

- DeleteAllNetworkPrinter : Boolean to delete or not the others network printers installed on the computer. By default, network printers aren't delete.

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/SYSTEM-Add-NetworkPrinter/Images/Add-NetworkPrinter-Exemple.png)