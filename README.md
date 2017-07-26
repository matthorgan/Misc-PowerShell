# Misc-PowerShell

This repository serves as a location for any miscelaneous PowerShell functions/scripts that aren't big enough to require their own repo.


### Get-IsapiDllStatus.ps1

This function accepts a list of web servers and returns ISAPI handler mapping permission information. I used this as part of a security as follows:
```powershell
# Import servers here
$Servers = Get-Content .\Servers.txt

$Creds = Get-Credential

# Create csv file of all websites that have ISAPI-Dll enabled (Execute)
$Servers | Get-IsapiDllStatus -Credential $Creds| Where-Object {$_.AccessPolicy -match "Execute"} | Export-Csv -Path "IsapiReport.csv" -Force -NoTypeInformation
```
