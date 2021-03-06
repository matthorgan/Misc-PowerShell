# Misc-PowerShell

This repository serves as a location for any miscellaneous PowerShell functions/scripts that aren't big enough to require their own repo.


### Get-IsapiDllStatus.ps1

This function accepts a list of web servers and returns ISAPI handler mapping permission information. Here is an example of using it to find all servers with websites that ISAPI handler mappings enabled and then exporting this output to CSV:
```powershell
# Import servers here
$Servers = Get-Content .\Servers.txt

$Creds = Get-Credential

# Create csv file of all websites that have ISAPI-Dll enabled (Execute)
$Servers | Get-IsapiDllStatus -Credential $Creds| Where-Object {$_.AccessPolicy -match "Execute"} | Export-Csv -Path "IsapiReport.csv" -Force -NoTypeInformation
```

### Install-Java.ps1

This function is used to install Java with parameters for common install options. You'll need Get-RemoteProgram available as this function uses it to check whether Java is installed: https://gallery.technet.microsoft.com/scriptcenter/Get-RemoteProgram-Get-list-de9fd2b4