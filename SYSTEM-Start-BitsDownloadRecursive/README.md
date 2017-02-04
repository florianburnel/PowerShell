# Start-BitsDownloadRecursive

Download files recursively with BITS with the same arborescence (after the download : source arborescence = destination arborescence).

# Example

```
    .\Start-BitsDownloadRecursive.ps1 -Source "\\192.168.1.150\Download\BITS\" -Dest "C:\temp\BITS"
```

- Source : The path to the source folder, all files in his subfolders will be copied. PLEASE, DO NOT INCLUDE A BACKSLASH AT THE END OF THE PATH

- Destination : The path to the destination folder, where you want to store downloaded files. PLEASE, DO NOT INCLUDE A BACKSLASH AT THE END OF THE PATH

![alt tag](https://raw.githubusercontent.com/florianburnel/PowerShell/master/SYSTEM-Start-BitsDownloadRecursive/Images/Start-BitsDownloadRecursive-Exemple.png)