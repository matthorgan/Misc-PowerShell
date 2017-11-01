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
        Uses Get-RemoteProgram for checking if Java is installed. Make sure this is available to you before
        you run this function: https://gallery.technet.microsoft.com/scriptcenter/Get-RemoteProgram-Get-list-de9fd2b4 

        This function does not handle all Java install options - only the most commonly used
        Java install parameters can be found at: https://www.java.com/en/download/help/silent_install.xml
        Tested with Java 6, 7 and 8

        Author: Matt Horgan
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [String]$Path,

        [Parameter(Mandatory=$true)]
        [ValidateSet('6', '7', '8')]
        [String]$Version,

        [Parameter(Mandatory=$false)]
        [String]$InstallDir,

        [Parameter(Mandatory=$false)]
        [String]$LogPath,

        [Parameter(Mandatory=$false)]
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
            if ($LogPath -notmatch "\w*.log\b") { 
                Write-Verbose "Creating new log file Java$($Version)_Setup.log in $LogPath"
                New-Item -Path $LogPath -ItemType Directory -Force -ErrorAction Stop
                $javaLogFolder = Join-Path -Path $LogPath -ChildPath "\Java$($Version)_Setup.log"
            } else {
                $javaLogFolder = Split-path -Path $LogPath -Parent 
                New-Item -Path $javaLogFolder -ItemType Directory -Force -ErrorAction Stop
            }
            Write-Verbose 'Adding InstallDir to Java install parameters'
            $arguments += ('/L "{0}"' -f $javaLogFolder)
        }

        # Add Static to arguments if used
        if ($PSBoundParameters.ContainsKey('Static')) {
            Write-Verbose 'Adding STATIC=1 to Java install parameters'
            $arguments += ('STATIC=1')
        }

        # Install Java 
        try {
            Write-Debug "Attempting to install Java $Version"
            $argumentString = $arguments -join " "
            Start-Process -FilePath $Path -ArgumentList $argumentString -Verbose -ErrorAction Stop 
            Write-Verbose "Java $Version Installed"
        }
        catch {
            Write-Error "Start-Process failed trying to install Java" -ErrorAction Continue
            throw $_     
        }
    } else {
        Write-Verbose "Java $Version already installed"
    }
}