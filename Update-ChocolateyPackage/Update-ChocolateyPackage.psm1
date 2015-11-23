#Requires -Version 5
#Requires -Modules PackageManagement -RunAsAdministrator

function Update-ChocolateyPackage {
<#
.SYNOPSIS
    Uses the Powershell PackageManagement module to update Chocolatey packages to the latest stable version.

.DESCRIPTION
    Uses the Powershell 5.0 PackageManagement module to update Chocolatey packages to the latest stable version.
    It compares the version currently installed Chocolatey packages on the local machine with the latest stable version.
    If the currently installed version is lower than the latest, it installs the latest version from the Chocolatey gallery.
    It takes care of uninstalling the previous version if necessary and installing dependencies.

    Currently, the PackageManagement module of PowerShell 5.0 doesn't include a Update-Package cmdlet.
    More information : https://github.com/OneGet/oneget/issues/58
    So the present function is an alternative.

    This function can also be used to check the Chocolatey packages for updates, without actually updating them.
    This can be done by adding the parameter -WhatIf .

.PARAMETER Name
    To specify the name of one or more installed Chocolatey packages which should be updated.
    If not specified, this function will check all the Chocolatey packages currently installed on the local machine.

.EXAMPLE
    Update-ChocolateyPackage -WhatIf

    Checks all the currently installed Chocolatey packages for updates without updating them.
    The output "What if" information is only in the case where a package is not up-to-date.

.EXAMPLE
    "putty","winscp","wireshark" | Update-ChocolateyPackage
    Checks only the 3 Chocolatey packages specified from the pipeline and for those which are not up-to-date,
    installs the latest version available from the Chocolatey gallery.

.NOTES
    Author : Mathieu Buisson

#>
    [CmdletBinding(SupportsShouldProcess)]
    
    Param(
        [Parameter(ValueFromPipeline=$True,Position=0)]
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
        foreach ($BoundParameterKey in $($PSBoundParameters.Keys)) {
            Write-Debug "Bound parameter : $BoundParameterKey"
        }

        # Removing the WhatIf parameter because Get-Package doesn't support this parameter
        If ($PSBoundParameters.ContainsKey('WhatIf')) {
            $PSBoundParameters.Remove('WhatIf')
        }
        $CurrentPackages = Get-Package @PSBoundParameters -ProviderName chocolatey

        Foreach ($CurrentPackage in $CurrentPackages) {

            Write-Verbose "Checking the package $($CurrentPackage.Name) for updates"
            $InstalledVersion = [Version]$($CurrentPackage.Version)
            $LatestPackage = Find-Package -ProviderName chocolatey -Name $($CurrentPackage.Name)
            $LatestVersion = [Version]$($LatestPackage.Version)
            
            If ($InstalledVersion -lt $LatestVersion) {
                If ($PSCmdlet.ShouldProcess($($CurrentPackage.Name), "Install-Package")) {
                    Install-Package -InputObject $LatestPackage -Confirm:$False
                }
            }
            Else {
                Write-Verbose "The package $($CurrentPackage.Name) is already up-to-date"
            }
        }
    }
    End {
    }
}