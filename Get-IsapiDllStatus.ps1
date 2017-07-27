<#
.SYNOPSIS
    Retrieves a list of all IIS sites on a server and their access policy for ISAPI handler mappings
.DESCRIPTION
    Long description
.EXAMPLE
    Get-IsapiDllStatus -ServerName server1
    Gets the ISAPI Dll status of the server 'server1'
.EXAMPLE
    Get-IsapiDllStatus -ServerName server1,server2,server3
    Gets the ISAPI Dll status of all servers specified (Note, these must be divided by a ",")
.EXAMPLE
    $Servers = "server1","server2","server3"
    $Servers | Get-IsapiDllStatus
    Takes the array of strings object from pipeline and gets the ISAPI Dll status of all servers specified
.INPUTS
    System.String
.OUTPUTS
    System.Management.Automation.PSCustomObject
.NOTES
    Author: Matt Horgan
#>
function Get-IsapiDllStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true)]
        [String[]]
        $ServerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    begin {
    }

    process {

        # Split the input to account for comma seperated input
        $Servers = $ServerName -split ","

        foreach ($Server in $Servers) {

            #######################################################
            # Construct script block ready to send to remote server
            $ScriptBlock = {

                # Check if IIS is installed on the server
                try {
                    $IisInstalled = Get-WmiObject -Query "select * from Win32_ServerFeature where ID='2'"
                }
                catch {
                    Write-Warning -Message "Couldn't execute Wmi Query on $Server. Please check this server manually."
                }


                if ($IisInstalled) {
                    # Import IIS module and get a list of IIS sites
                    Import-Module WebAdministration
                    $IisSiteNames = Get-ChildItem "IIS:\Sites\" | Select-Object -ExpandProperty Name

                    # Add server root option to $IisSiteNames
                    $IisSiteNames += "$env:COMPUTERNAME IIS Root Settings"

                    foreach ($IisSiteName in $IisSiteNames) {
                        try {
                            if ($IisSiteName -eq "$env:COMPUTERNAME IIS Root Settings") {
                                $IisSiteHandlerSettings = Get-WebConfiguration "/system.webServer/handlers"
                                $AccessPolicy = $IisSiteHandlerSettings.AccessPolicy
                            }
                            else {
                                $IisSiteHandlerSettings = Get-WebConfiguration "/system.webServer/handlers" -PSPath "IIS:\Sites\$IisSiteName"
                                $AccessPolicy = $IisSiteHandlerSettings.AccessPolicy
                            }
                        }
                        catch {
                            $AccessPolicy = "Error reading handler mappings"
                        }

                        [PSCustomObject]@{
                            "ServerName"   = $env:COMPUTERNAME
                            "IisSiteName"  = $IisSiteName
                            "AccessPolicy" = $AccessPolicy
                        }
                    }
                }
                else {
                    [PSCustomObject]@{
                        "ServerName"   = $env:COMPUTERNAME
                        "IisSiteName"  = "IIS Not Installed"
                        "AccessPolicy" = "N/A"
                    }
                }
            }
            ## End Script Block
            #######################################################

            try {
                Invoke-Command -ComputerName $Server -ScriptBlock $ScriptBlock -Credential $Credential -ErrorAction Stop | Select-Object ServerName, IisSiteName, AccessPolicy
            }
            catch {
                Write-Warning -Message "Couldn't run remote script on $Server. Please check this manually."
            }
        }
    }
    end {
    }
}