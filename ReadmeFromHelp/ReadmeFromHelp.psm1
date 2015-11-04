#Requires -Version 3
function New-ReadmeFromHelp {
<#
.SYNOPSIS
    Generates a README.md file from the comment-based help contained in the specified PowerShell module file.

.DESCRIPTION
    Generates a README.md file from the help contained in the specified Powershell module file.
    The generated README.md file's purpose is to serve as a brief documentation for the module on GitHub.  
    This README file is created in the same directory as the module file.  
    It uses GitHub Flavored Markdown, so the GitHub website will format it nicely.

    This works with any PowerShell module (script or compiled) and any help (comment-based or XML-based) as long as it is accessible via Get-Help.

.PARAMETER ModuleFile
    To specify the path to the module file you wish to create a README file for.

.EXAMPLE
    New-ReadmeFromHelp -ModuleFile ".\Example.psm1"

    Creates a README file for the script module Example.psm1, in the same directory.
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Mandatory=$True,Position=0)]
        [validatescript({ Test-Path $_ })]
        [string]$ModuleFile
    )

    Begin {
        Try {
            Import-Module $ModuleFile -Force
        }
        Catch {
            Throw $_.Exception
        }
        $FullModulePath = Resolve-Path -Path $ModuleFile
        $ParentDirectory = Get-ChildItem $FullModulePath | Select-Object -ExpandProperty DirectoryName

        $Module = Get-Module | Where-Object { $_.Path -eq $FullModulePath }
        $FirstLine = $Module.Definition -split "`n" | Select-Object -First 1
        If ($FirstLine -like "#Requires*") {
            $PSVersionRequired = $($FirstLine -split " " | Select-Object -Last 1)
        }

        # Preparing a variable which will store strings making up the content of the README file
        $Readme = @()
    }
    Process {

        #region Module description
        $Commands = Get-Command -Module $Module
        Write-Debug "Commands in the module : $($Commands.Name)"

        $CommandsCount = $($Commands.Count)

        $Readme += "##Description :"
        $Readme += "`n`r"

        If ($CommandsCount -gt 1) {

            # At the end of the following string, there are 2 spaces
            # This is how we do a new line in the same paragraph in GitHub flavored markdown
            $Readme += "This module contains $CommandsCount cmdlets :  "
            Foreach ($Command in $Commands) {
                $Readme += "**$($Command.Name)**  "
            }            
        }
        Else {
            $Readme += "This module contains 1 cmdlet : **$($Commands.Name)**.  "
        }
        If ($PSVersionRequired) {
            $Readme += "It requires PowerShell version $PSVersionRequired (or later)."
        }
        $Readme += "`n`r"
        #endregion Module description

        Foreach ($Command in $Commands) {
            $Name = $Command.Name
            $Readme += "##$Name :"
            $Readme += "`n`r"

            $HelpInfo = Get-Help $Command.Name -Full
            $Readme += $HelpInfo.description

            #region Parameters
            $Readme += "###Parameters :"
            $Readme += "`n`r"

            $CommandParams = $HelpInfo.parameters.parameter
            Write-Debug "Command parameters for $Name : $($CommandParams.Name)"

            Foreach ($CommandParam in $CommandParams) {
                $Readme += "**" + $($CommandParam.Name) + " :** " + $($CommandParam.description.Text) + "  "

                If ( $($CommandParam.defaultValue) ) {
                    $ParamDefault = $($CommandParam.defaultValue).ToString()
                    $Readme += "If not specified, it defaults to $ParamDefault ."
                }
                $Readme += "`n`r"
            }
            #endregion Parameters

            #region Examples
            $Readme += "###Examples :`n`r"
            $Readme += $HelpInfo.examples | Out-String

            #endregion Examples
        }
    }
    End {
        $ReadmeFilePath = Join-Path -Path $ParentDirectory -ChildPath "README.md"
        $Readme | Out-File -FilePath $ReadmeFilePath -Force

        Remove-Module $Module
    }
}