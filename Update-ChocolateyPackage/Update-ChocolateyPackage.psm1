#Requires -Version 5
#Requires -Modules PackageManagement -RunAsAdministrator

function Update-ChocolateyPackage {
<#
.SYNOPSIS
    Uses the Powershell PackageManagement module to update Chocolatey packages to the latest stable version.

.DESCRIPTION
    Uses the Powershell 5.0 PackageManagement module to update Chocolatey packages to the latest stable version.
    It compares the version currently installed Chocolatey packages on the local machine with the latest stable version.
    If the currently installed version is lower than the latest, it installs the latest version.
    It takes care of uninstalling the previous version if necessary and of installing dependencies.

    Currently, the PackageManagement module of PowerShell 5.0 doesn't include a Update-Package cmdlet.
    More information : https://github.com/OneGet/oneget/issues/58
    So the present function is an alternative.

.PARAMETER Name
    To specify the path to the module file you wish to create a README file for.

.EXAMPLE
    New-ReadmeFromHelp -ModuleFile ".\Example.psm1"

    Creates a README file for the script module Example.psm1, in the same directory.
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Position=0)]
        [string[]]$Name
    )

    Begin {
        If (-not (Get-PackageProvider -Name chocolatey)) {

            # This is just to automatically install the chocolated provider
            Find-Package -Name 7zip | Out-Null
        }
        If (-not ((Get-PackageSource -Name chocolatey).IsTrusted)) {
            # Setting Chocolatey as a trusted package source
            Set-PackageSource -Name chocolatey -Trusted
        }
    }
    Process {
        $PSBoundParameters.Add('ProviderName',"chocolatey")
        $CurrentPackages = Get-Package @PSBoundParameters

        Foreach ($CurrentPackage in $CurrentPackages) {
            $InstalledVersion = [Version]$($CurrentPackage.Version)
            
        }
    }
    End {
    }
}
#Update-ChocolateyPackage -Name 7zip,vlc,foxitreader | ft