﻿#Requires -Version 5
function ConvertFrom-DscMof {
<#
.SYNOPSIS
   Parses one or more MOF file and converts the resource instances it contains to PowerShell Objects
.DESCRIPTION
   Parses one or more MOF file and converts the resource instances it contains to PowerShell Objects.
   The custom output object for each resource instance exposes all the resource instance properties and settings.
   
.PARAMETER Path
    The path of one or more MOF files.
    FileInfo objects returned by Get-ChildItem can be bound to this parameter from the pipeline.
.EXAMPLE
   Get-ChildItem "C:\DSCConfigs\Output" -File -Filter "*.mof" -Recurse | ConvertFrom-DscMof
#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidateScript({Test-Path $_ -PathType Leaf -Include *.mof})]
        [Alias('FullName')]
        [string[]]$Path
    )

    Begin {
    }
    Process {
        Write-Verbose "Bound parameters:  $($PSBoundParameters.Values)"
        Foreach ($MofFile in $Path) {

            Write-Verbose "Working on the MOF file : $MofFile"
            $FileContent = Get-Content -Path $MofFile
            If ( -not($FileContent)) {
                Write-Warning "Skipping $MofFile as it is empty."
                Continue
            }

            $LineWithFirstBrace = Select-String -Path $MofFile -Pattern "instance of " | Where-Object { $_.Line -notmatch 'MSFT_Credential' } | Select-Object -First 1 | Select-Object -ExpandProperty LineNumber

            $TargetNode = ($FileContent[1] -split "'")[1]
            $GenerationDate = ($FileContent[3] -split "=")[1]

            # Removing the lines preceding the first resource instance
            $Resources = $FileContent | Select-Object -Skip ($LineWithFirstBrace) | Where-Object {$_ -notmatch "^\s*$"}


            $Resources = $Resources -replace ";",""

            # Reformatting multi-value properties to allow ConvertFrom-StringData to process them
            $Resources = $resources -join "`n"
            $Resources = $Resources -replace '(?m)\{[\r\n]+\s*',''
            $Resources = $Resources -replace 'instance of \w+.*',''
            $Resources = $Resources -replace '(?m)\,[\r\n]+\s*',','
            $Resources = $Resources -replace "(?m)\}[\r\n]+^\s*$",""
            $Resources = $Resources -replace "(?m)$\s*\}[\r\n]+","`n"

            $Instances = ($Resources -Split '(?m)^\s*$')

            # Removing the empty last item and the ConfigurationDocument instance from the collection
            $ResourceInstances = $Instances | Select-Object -SkipLast 1
            Write-Verbose "Number of resource instances in this MOF file : $($ResourceInstances.Count)"

            Foreach ($ResourceInstance in $ResourceInstances) {
                $ResourceHashTable = $ResourceInstance | ConvertFrom-StringData

                # Removing double quotes at beginning and end of the hashtable values
                Foreach ($Key in $($ResourceHashTable.Keys)) {
                    $ResourceHashTable[$Key] = ($ResourceHashTable[$Key]).Trim('}')
                    $ResourceHashTable[$Key] = ($ResourceHashTable[$Key]).Trim('"')
                    Write-Verbose "Resource instance property:  $Key = $($ResourceHashTable[$Key])"
                }

                # Building the properties for our custom object
                # Not just using the above hashtable because I want these properties to be always in the same order
                $ResourceInstanceProperties = [ordered]@{
                        'MOF file Path'=$MofFile
                        'MOF Generation Date'=[DateTime]$GenerationDate
                        'Target Node'=$TargetNode
                        'Resource ID'=$($ResourceHashTable.ResourceID)
                        'DSC Configuration Info'=$($ResourceHashTable.SourceInfo)
                        'DSC Resource Module'=$($ResourceHashTable.ModuleName)
                        'DSC Resource Module Version'=$($ResourceHashTable.ModuleVersion)
                }

                # Removing the elements of the hashtable which are already used in $ResourceInstanceProperties
                $ResourceHashTable.Remove('ResourceID')
                $ResourceHashTable.Remove('SourceInfo')
                $ResourceHashTable.Remove('ModuleName')
                $ResourceHashTable.Remove('ModuleVersion')

                # Adding the remaining hashtable elements to our list of properties
                $ResourceInstanceProperties += $ResourceHashTable

                $ResourceInstanceObj = New-Object -TypeName PSObject -Property $ResourceInstanceProperties
                $ResourceInstanceObj
            }
        }
    }
}