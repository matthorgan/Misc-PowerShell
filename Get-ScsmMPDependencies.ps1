function Get-ScsmMPDependencies {
    <#
    .SYNOPSIS
        Get SCSM management pack dependencies
    .DESCRIPTION
        Takes single or multiple management packs/management pack bundles and gets the related dependencies
    .PARAMETER ManagementPack
        Full path to the management pack(s)/management pack bundle(s). Path must end in .mp or .mpb
    .EXAMPLE
        Get-ScsmMPDependencies -ManagementPack myManagementPack.mp

        Lists the dependencies for myManagementPack.mp management pack
    .EXAMPLE
        $allManagementPacks = Get-ChildItem -Recurse | Where-Object Name -match '\.mp$|\.mpb$' | Select-Object Name
        $allManagementPacks | Get-ScsmMPDependencies

        Gets all management packs and management pack bundles in a directory and gets all dependencies required for
        the management packs
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [ValidatePattern('\.mpb$|\.mp$')]
        [String[]]$ManagementPack
    )

    begin {
        #region SCSM Module Setup
        try {
            Write-Verbose 'Importing System Center Service Manager Cmdlets'
            Import-Module "$env:ProgramFiles\Microsoft System Center\Service Manager\Powershell\System.Center.Service.Manager.psd1" -Verbose:$false -ErrorAction 'Stop'
        }
        catch {
            Write-Error "Couldn't import SCSM modules" -ErrorAction 'Continue'
            throw $_
        }
        #endregion SCSM Module Setup
    }

    process {
        foreach ($pack in $ManagementPack) {
            # Different cmdlets for management packs and management pack bundles
            if ($pack -match '\.mp$') {
                try {
                    # Get management pack dependencies
                    Write-Verbose "Attempting to get dependencies for ManagementPack [$pack]"
                    $dependencies = (Get-SCSMManagementPack -ManagementPackFile $pack -ErrorAction 'Stop').References.Values
                }
                catch {
                    Write-Error "Couldn't get SCSM management pack [$pack]" -ErrorAction 'Continue'
                    throw $_
                }
            }
            elseif ($pack -match '\.mpb$') {
                try {
                    # Get bundle version
                    Write-Verbose "Attempting to get dependencies for ManagementPack Bundle [$pack]"
                    $dependencies = (Get-SCSMManagementPack -BundleFile $pack -ErrorAction 'Stop').References.Values
                }
                catch {
                    Write-Error "Couldn't get SCSM management pack bundle [$pack]" -ErrorAction 'Continue'
                    throw $_
                }
            }

            # Return dependencies
            $dependencies
        }
    }
}

