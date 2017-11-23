function Install-Java {
    <#
    .SYNOPSIS
        Installs Java
    .DESCRIPTION
        Checks whether Java is installed already and installs Java. Current supported versions are 6, 7
    .EXAMPLE
        PS C:\> Install-Java -Path C:\jre.exe -Version 7
        If not already installed, installs Java 7 
    .EXAMPLE
        PS C:\> Install-Java -Path C:\jre.exe -Version 7 -InstallDir C:\example\ -LogPath C:\javaLog.log -Static
        If not already installed, installs Java 7 into C:\example\, outputs the install log to C:\javaLog.log 
        and finally sets the Java installation to static
    .NOTES
        This function does not handle all Java install options - only the most commonly used
        Java install parameters can be found at: https://www.java.com/en/download/help/silent_install.xml
        Tested with Java 6, 7 and 8

        Author: Matt Horgan
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateSet('6', '7', '8')]
        [Int16]$Version,

        [Parameter(Mandatory = $false)]
        [String]$InstallDir,

        [Parameter(Mandatory = $false)]
        [String]$LogPath,

        [Parameter(Mandatory = $false)]
        [Switch]$Static
    )

    # Check Java is installed
    Write-Verbose "Checking if Java $Version is already installed"
    $javaInstalled = ((Get-RemoteProgram -Property VersionMajor | 
        Where-Object {$_.ProgramName -match 'Java' -and $_.VersionMajor -match $Version}).ProgramName).Count -gt 0

    if (-not $javaInstalled) {
        Write-Verbose "Java $Version not installed"

        # Arguments to pass into start installation process
        $arguments = @(
            '/s'
        )

        # Add InstallDir to arguments if used
        if ($PSBoundParameters.ContainsKey('InstallDir')) {
            Write-Verbose 'Adding InstallDir to Java install parameters'
            $arguments += ('INSTALLDIR="{0}"' -f $InstallDir)
        }

        # Add LogPath to arguments if used
        if ($PSBoundParameters.ContainsKey('LogPath')) {    
            try {
                if ($LogPath -notmatch "\w*.log\b") { 
                    Write-Verbose "Creating new log file Java$($Version)_Setup.log in $LogPath"
                    $javaLogPath = Join-Path -Path $LogPath -ChildPath "\Java$($Version)_Setup.log" -ErrorAction Stop
                    New-Item -Path $LogPath -ItemType Directory -Force -ErrorAction Stop | Out-String |
                        Write-Verbose 
                }
                else {
                    $javaLogPath = $LogPath
                    $javaLogFolder = Split-Path -Path $LogPath -Parent -ErrorAction Stop  
                    New-Item -Path $javaLogFolder -ItemType Directory -Force -ErrorAction Stop | 
                    Out-String | Write-Verbose  
                }
                Write-Verbose 'Adding InstallDir to Java install parameters'
                $arguments += ("/L `"$javaLogPath`"")
            }
            catch {
                Write-Error "Error setting up $javaLogFolder for Java log path" -ErrorAction Continue
                throw $_ 
            }

        }

        # Add Static to arguments if used
        if ($PSBoundParameters.ContainsKey('Static')) {
            Write-Verbose 'Adding STATIC=1 to Java install parameters'
            $arguments += ('STATIC=1')
        }

        # Install Java 
        try {
            Write-Verbose "Attempting to install Java $Version"
            $argumentString = $arguments -join " "
            $installParams = @{
                FilePath = $Path 
                ArgumentList = $argumentString
                Verbose = $VerbosePreference
                ErrorAction = 'Stop'
            }
            $installOutput = Invoke-Process @installParams

            Write-Verbose "StdOut information from Java install (Non terminating - safe to ignore):"
            Write-Verbose ($installOutput | Out-String)
            Write-Verbose "Java $Version Installed"
        }
        catch {
            Write-Error "Invoke-Process failed trying to install Java" -ErrorAction Continue
            throw $_     
        }
    }
    else {
        Write-Verbose "Java $Version already installed"
    }
}