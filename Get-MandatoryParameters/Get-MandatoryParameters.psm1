function Get-MandatoryParameters {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [ValidateScript({ Get-Command $_ -ErrorAction SilentlyContinue })]        
        [string]$CmdString
    )
 
    $CmdData = Get-Command $CmdString
 
    # If the $CmdString provided by the user is an alias, resolve to the cmdlet name
    If ($CmdData.CommandType -eq "Alias") {
        $CmdData = Get-Command (Get-Alias $CmdString).Definition
    }
 
    $MandatoryParameters = $CmdData.Parameters.Values | Where { $_.Attributes.Mandatory -eq $True }
 
    Foreach ( $MandatoryParameter in $MandatoryParameters ) {
 
        $ParameterHelp = Get-Help $CmdString -Parameter $MandatoryParameter.Name
 
        $Props = [ordered]@{'Name'=$MandatoryParameter.Name
                        'Parameter Set'=$MandatoryParameter.Attributes.ParameterSetName
                        'Position'=$MandatoryParameter.Attributes.Position
                        'Data Type'=$MandatoryParameter.ParameterType
                        'Pipeline Input'=$ParameterHelp.pipelineInput
                        'Accepts Wildcards'=$ParameterHelp.globbing
                        }
 
        $Obj = New-Object -TypeName psobject -Property $Props
        $Obj
    }
}