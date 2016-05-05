<#
.Synopsis
   Parses all the MOF files in the specified directory and the resource instances they contain to PowerShell Objects
.DESCRIPTION
   Parses all the MOF files in the specified directory and the resource instances they contain to PowerShell Objects
.EXAMPLE
   ConvertFrom-DscMof -Path C:\DSCConfigs\MOFs -Recurse
.EXAMPLE
   Another example of how to use this cmdlet
#>
function ConvertFrom-DscMof
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string[]]$Path,

        [switch]$Recurse
    )

    Begin {
    }
    Process {
        $MofFiles = Get-ChildItem -Path $Path -File -Filter "*.mof" -Recurse:$Recurse

        Foreach ($MofFile in $MofFiles) {

            $FilePath = $MofFile.FullName
            $LineWithFirstBrace = Select-String -Path $FilePath -Pattern "{" | Select-Object -First 1 | Select-Object -ExpandProperty LineNumber

            # Removing empty lines
            $FileContent = Get-Content -Path $FilePath | Where-Object {$_ -notmatch "^\s*$"}
            $TargetNode = ($FileContent[1] -split "'")[1]
            $GenerationDate = ($FileContent[3] -split "=")[1]

            # Removing the lines preceding the first resource instance
            $Resources = $FileContent | Select-Object -Skip ($LineWithFirstBrace - 2)

            $Resources = $Resources -replace ";",""
            $Resources = $Resources | Where-Object {$_ -notmatch "instance of "}

            #Removing empty lines again
            $Resources = $Resources | Where-Object {$_ -notmatch "^\s*$|\{"}

            $ResourceInstances = $Resources -join "`n" | ConvertFrom-String -Delimiter '}'

        }
    }
}