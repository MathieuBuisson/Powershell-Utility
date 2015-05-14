#Requires -Version 4.0
function Compare-FolderFiles {

<#
.SYNOPSIS
   Compares the files in one folder with the files in another folder.

.DESCRIPTION
   Compares the files in one folder with the files in another folder.
   Uses a MD5 hash value to uniquely identify and compare the content of the files.

.PARAMETER ReferenceFolder
    Folder used as a reference for comparison.
    The command checks that the value for this parameter is a valid path.

.PARAMETER DifferenceFolder
    Specifies the folder that is compared to the reference folder.
    Accepts pipeline input, and the command checks that the value for this parameter is a valid path.

.PARAMETER Recurse
    Compares all files in the Reference folder and difference folder, including their child folders. 

.PARAMETER Force
    Includes the hidden files and hidden child folders.

.PARAMETER ShowDifferenceSide
    Shows only the different files which are located in the difference folder.

.PARAMETER ShowReferenceSide
    Shows only the different files which are located in the reference folder.

.PARAMETER ShowNewer
    For files with the same name which exist in the same location in the reference folder and the `
    difference folder (but have different hash values), this shows only the newer version of the file

.EXAMPLE
   Compare-FolderFiles -ReferenceFolder C:\test -DifferenceFolder C:\test2 -Force

   Compares the files in C:\test2 with the files in C:\test, including hidden files

.EXAMPLE
   "C:\test2" | Compare-FolderFiles -ReferenceFolder C:\test -Recurse -ShowReferenceSide

   Compares the files in the path specified from pipeline input recursively to the files in C:\test `
   and shows only the different files which are located in the reference folder

.EXAMPLE 
    Compare-FolderFiles C:\test C:\test2 -ShowNewer

    Compares the files in C:\test2 with the files in C:\test, showing only the more recent version of `
    files which have the same name and are in the same location on both sides.

.LINK
   Get-FileHash
#>
    [CmdletBinding()]   
    Param (
        [Parameter(Mandatory=$True,Position=0)]
        [validatescript({ Test-Path $_ })]
        [string]$ReferenceFolder,
                
        [Parameter(Mandatory=$True,ValueFromPipeline=$true,Position=1)]
        [validatescript({ Test-Path $_ })]
        [string]$DifferenceFolder,
        
        [switch]$Recurse,
        
        [switch]$Force,
        
        [switch]$ShowDifferenceSide,
        
        [switch]$ShowReferenceSide,

        [switch]$ShowNewer
    )
    Begin {
       # Clearing the default parameter values in the function's scope
       $PSDefaultParameterValues.Clear()
    }
    Process {

        $RefFolderFiles = Get-ChildItem -Path $ReferenceFolder -Recurse:$Recurse -Force:$Force -File
        $DiffFolderFiles = Get-ChildItem -Path $DifferenceFolder -Recurse:$Recurse -Force:$Force -File
        Write-Verbose "`$RefFolderFiles : $RefFolderFiles"
        Write-Verbose "`$DiffFolderFiles : $DiffFolderFiles"

        $RefFileHashes = $RefFolderFiles | Get-FileHash -Algorithm MD5
        $DiffFileHashes = $DiffFolderFiles | Get-FileHash -Algorithm MD5
        
        $UniqueFiles = Compare-Object $RefFileHashes $DiffFileHashes -Property Hash,Path
        $Compare = Compare-Object $RefFileHashes $DiffFileHashes -Property Hash

        If ($Compare -eq $null) {
            Write-Verbose "Files in $DifferenceFolder are identical to files in $ReferenceFolder"
        }
        Else { 
            # Preparing an empty array to store each iteration of a custom difference object
            $CustomDiffObj_Collection = @() 
                     
            Foreach ($DiffObj in $Compare) {                
                $DiffObjWithPath = $UniqueFiles | Where-Object { $_.Hash -eq $DiffObj.Hash }
                $DiffObjFile = Get-ChildItem -Path $DiffObjWithPath.Path
                $DiffObjProperties = [ordered]@{'Name'=$DiffObjFile.Name
                                                'Path'=$DiffObjFile.FullName
                                                'LastEditTime'=$DiffObjFile.LastWriteTime
                                                'Hash'=$DiffObj.Hash
                                                'Folder'=if ($DiffObjFile.Directory.FullName -eq $ReferenceFolder -or $DiffObjFile.Directory.Parent.FullName -eq $ReferenceFolder -or $DiffObjFile.Directory.Parent.Parent.FullName -eq $ReferenceFolder) {"Reference"} Else {"Difference"}
                                                }

            # Building a custom object from the list of properties in $DiffObjProperties
            $CustomDiffObj = New-Object -TypeName psobject -Property $DiffObjProperties

            # Storing each $CustomDiffObj every time we go through the loop
            $CustomDiffObj_Collection += $CustomDiffObj
            }
        } 
    }
    End {
        If ($PSBoundParameters.ContainsKey('ShowDifferenceSide') -and $ShowDifferenceSide -eq $True) {
            $CustomDiffObj_Collection | Where-Object { $_.Folder -eq "Difference" }
        }
        ElseIf ($PSBoundParameters.ContainsKey('ShowReferenceSide') -and $ShowReferenceSide -eq $True) {
            $CustomDiffObj_Collection | Where-Object { $_.Folder -eq "Reference" }
        }
        ElseIf ($PSBoundParameters.ContainsKey('ShowNewer') -and $ShowNewer -eq $True) {

            If (-not ($ReferenceFolder.EndsWith("\") )) {
                $ReferenceFolder += "\" }

            If (-not ($DifferenceFolder.EndsWith("\") )) {
                $DifferenceFolder += "\" }

            Write-Verbose "`$ReferenceFolder : $ReferenceFolder"
            Write-Verbose "`$DifferenceFolder : $DifferenceFolder"

            # Preparing an empty array to store each iteration of final difference object
            $FinalDiffObj_Collection = @()

            Foreach ($FinalDiffObj in $CustomDiffObj_Collection) {
                
                # Adding a property to identify the files with the same name and the same location within the reference and difference folder

                $PathWithinFolder = if ($FinalDiffObj.Folder -eq "Reference") {
                                    $FinalDiffObj.Path.Replace("$ReferenceFolder", "") } Else {
                                    $FinalDiffObj.Path.Replace("$DifferenceFolder", "")}

                $FinalDiffObj | Add-Member –MemberType NoteProperty –Name PathWithinFolder –Value $PathWithinFolder
                $FinalDiffObj_Collection += $FinalDiffObj
            }
            # Grouping together the files with the same name and the same location within the reference and difference folder
            $GroupedByPathWithinFolder = $FinalDiffObj_Collection | Group-Object -Property PathWithinFolder
            
            Foreach ($FileGroup in $GroupedByPathWithinFolder) {
                If ($FileGroup.Count -gt 1) {
                    if ( ($Filegroup.Group[0].LastEditTime) -ge ($Filegroup.Group[1].LastEditTime) ) {
                        $FileGroup.Group[0]
                    }
                    Else { $FileGroup.Group[1] }
                 }
                 Else { $Filegroup.Group }
            }
        }
        Else {
            # Sorting by name and path to make it easier to see the last version of a given file, if it is in both folders
            $CustomDiffObj_Collection | Sort-Object -Property Name,Path
        }
    }
}
