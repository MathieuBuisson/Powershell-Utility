#Requires -Version 4
function Get-Podcast {
<#
.SYNOPSIS
    Retrieves information on podcast(s) episodes from the specified podcast URL(s).

.DESCRIPTION
    Retrieves information on podcast(s) episodes from the podcast RSS/Atom feed(s) specified in the -Url parameter or from a file.

.PARAMETER Url
    RSS/Atom feed URLs to query for podcasts information.
    Can take a comma-separated list of URLs.

.PARAMETER List
    To specify the path to a text file listing the RSS/Atom URLs of podcasts to query.
    The file should contain one podcast URL per line.

.PARAMETER FromLastDays
    To retrieve only the podcast episodes newer than the specified number of days ago.
    The default is 365 days.

.PARAMETER Last
    To specify how many of the latest episodes you want to retrieve, for each podcast.
    If the user specifies both -FromLastDays and -Last parameters, -FromLastDays takes precedence.
    This means that if the last episode of a given podcast is older than the number of days specified with -FromLastDays, no episode will be ouput for this podcast, regardless of the value of the -Last parameter.

.EXAMPLE
    Get-Podcast -List C:\Documents\Mypodcasts.txt -Last 1
    To get the last episode for each podcast listed in the file Mypodcasts.txt .

.EXAMPLE
    Get-Podcast -Url http://feeds.feedburner.com/PowerScripting -FromLastDays 30
    To get the episodes from the last 30 days of the PowerScripting podcast.

.EXAMPLE 
    "http://feeds.feedburner.com/RunasRadio","http://feeds.feedburner.com/PowerScripting" |
    Get-Podcast -Last 2
    To get the last 2 episodes from the podcasts URLs input from the pipeline.

#>
    [CmdletBinding(DefaultParameterSetName="List")]
    
    Param(
        [Parameter(Position=0,ValueFromPipeline=$True,ParameterSetName='Url',
                   HelpMessage="One or more RSS/Atom feed URLs to query for podcasts information")]
        [string[]]$Url,
        
        [Parameter(Position=0,ParameterSetName='List')]
        [validatescript({ Test-Path $_ })]
        [string]$List,

        [int]$FromLastDays = 365,

        [int]$Last = 99
    )

    Begin {
        If ($PSCmdlet.ParameterSetName -eq "List") {
            $Url = Get-Content $List
        }
        $PublishedFromDate = (Get-Date).AddDays(-$FromLastDays)
        Write-Debug "`$PublishedFromDate : $PublishedFromDate ."        
    }
    Process {
        Foreach ( $PodcastURL in $Url ) {
            Try {
            [xml]$PodcastFeed = Invoke-WebRequest -Uri $PodcastURL
            }
            Catch {
                Write-Error $_.Exception.Message
                Continue
            }
            $PodcastFeedItems = $PodcastFeed.rss.channel.Item
            $PodcastTitle = $PodcastFeed.rss.channel.title

            # Initializing a counter variable for each podcast
            $EpisodeCount = 0
            Write-Debug "`$EpisodeCount is : $EpisodeCount ."

            # Avoiding useless looping if the podcast feed contains less episodes than the value of $Last
            If ( $PodcastFeedItems.count -le $Last ) {
                $Last = $PodcastFeedItems.count
            }
            Write-Debug "`$Last : $Last ."
             
            Foreach ( $PodcastFeedItem in $PodcastFeedItems ) {
                $CustomProps = [ordered]@{'PodcastTitle'=$PodcastTitle
                                          'PodcastUrl'=$PodcastURL
                                          'Title'=$PodcastFeedItem.Title
                                          'Summary'=$PodcastFeedItem.Summary
                                          'Link'=$PodcastFeedItem.Link
                                          'PublishedDate'=$PodcastFeedItem.pubDate.Substring(0,25) -as [datetime]
                                          'Author'=$PodcastFeedItem.Author
                                          'MediaFileUrl'=$PodcastFeedItem.Enclosure.Url
                                          'MediaFileName'=($PodcastFeedItem.Enclosure.Url -split '/')[-1]}

                $PodcastEpisodeObj = New-Object -TypeName psobject -Property $CustomProps
                
                If ($PodcastEpisodeObj.PublishedDate -ge $PublishedFromDate) {
                    Write-Output $PodcastEpisodeObj
                }
                # Incrementing the counter variable each time we go through the while loop
                # Incrementing it here as opposed to within the If statement because if the user specifies both -FromLastDays and -Last parameters, -FromLastDays takes precedence. This means that if the last episode of a given podcast is older than $PublishedFromDate, no episode will be ouput for this podcast.
                $EpisodeCount += 1
                Write-Debug "`$EpisodeCount : $EpisodeCount ."

                # Breaking out of the Foreach loop to get only the number of latest episodes specified in $Last
                If ($EpisodeCount -ge $Last) {
                    break
                }
            }
        }
    }
}
function Save-Podcast {
<#
.SYNOPSIS
    Downloads podcast(s) episodes from the specified podcast URL(s).

.DESCRIPTION
    Downloads podcast(s) episodes from the podcast RSS/Atom feed(s) specified in the -Url parameter or from a file.
    It can also take the podcast objects piped from Get-Podcast.

.PARAMETER Url
    RSS/Atom feed Url for the podcasts to query for download.
    Can take a comma-separated list of URLs.

.PARAMETER List
    To specify the path to a text file listing the RSS/Atom URLs of podcasts.
    The file should contain one podcast URL per line.

.PARAMETER MediaFileUrl
    To specify one or more mediafiles to download by entering their direct URL.

.PARAMETER FromLastDays
    To download only the podcast episodes newer than the specified number of days ago.
    The default is 365 days.

.PARAMETER Last
    To specify how many of the latest episodes you want to download, for each podcast.
    If the user specifies both -FromLastDays and -Last parameters, -FromLastDays takes precedence.
    This means that if the last episode of a given podcast is older than the number of days specified with -FromLastDays, no episode will be ouput for this podcast, regardless of the value of the -Last parameter.

.PARAMETER Destination
    To specify the destination folder where to save the podcast files

.EXAMPLE
    Save-Podcast -List C:\Documents\Mypodcasts.txt -Last 1 -Destination $env:USERPROFILE\desktop
    To download the last episode for each podcast listed in the file Mypodcasts.txt to the desktop.

.EXAMPLE
    Save-Podcast -Url http://feeds.feedburner.com/PowerScripting -FromLastDays 30
    To download the episodes from the last 30 days of the PowerScripting podcast to the current directory.

.EXAMPLE
    Get-Podcast -List C:\Documents\Mypodcasts.txt -Last 1 | Save-Podcast
    To download the last episode for each podcast listed in the file Mypodcasts.txt, using pipeline input.
#>
    [CmdletBinding(DefaultParameterSetName="List")]
    
    Param(
        [Parameter(Position=0,ParameterSetName='Url')]
        [string[]]$Url,
        
        [Parameter(Position=0,ParameterSetName='List')]
        [validatescript({ Test-Path $_ })]
        [string]$List,

        [Parameter(Position=0,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,
        ParameterSetName='MediaFileUrl')]
        [string[]]$MediaFileUrl,

        [validateScript({Test-Path $_ -PathType Container })]
        [string]$Destination,

        [int]$FromLastDays = 365,

        [int]$Last = 99
    )

    Begin {        
        If ((Get-Service -Name "BITS").Status -eq 'Stopped') {
            Write-Verbose "Starting BITS"            
            Start-Service -Name BITS
            # Setting a variable to indicate if BITS was stopped, if yes, we are going to stop it after the download is finished
            $BITSWasStopped = $True
        }
        else {            
            $BITSWasStopped = $False
        }
    }
    Process {
        If ($MediaFileUrl) {
            Foreach ( $MediaFile in $MediaFileUrl ) {
                Write-Debug "`$MediaFile : $MediaFile "

                $MediaFileName = ($MediaFile -split '/')[-1]
                Write-Debug "`$MediaFileName : $MediaFileName "

                If (-not ($Destination)) {
                    # Downloading to the current directory by default
                    $OutFile = Join-Path -Path $PWD -ChildPath $MediaFileName
                }
                Else {
                    $OutFile = Join-Path -Path $Destination -ChildPath $MediaFileName
                }
                Write-Debug "`$OutFile : $OutFile "

                # Using the parameter -Asynchronous to allow downloading multiple files in parallel
                $Job = Start-BitsTransfer -DisplayName "Podcast" -Source $MediaFile -Destination $OutFile -Asynchronous -Priority Foreground -RetryInterval 60
                
                # Waiting just a little bit to check if the connection to the URL fails
                Start-Sleep -Seconds 1
                    
                # Error handling : Try/Catch doesn't work because it is a background job
                If ($Job.JobState -eq "Error") {
                    Write-Error "The download of $($Job.FileList.RemoteName) has failed. `r`n$($Job.ErrorDescription) "
                    $Job | Remove-BitsTransfer
                    Continue
                }                       
            }
            # Waiting for all jobs to start before calculating the total download size
            While (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object { $_.JobState -eq "Connecting" }) {
                Start-Sleep -Milliseconds 100
            }
            [int]$InitialBytesTotal = ((Get-BitsTransfer -Name "Podcast" | Measure-Object -Property BytesTotal -Sum).Sum)/1MB

            While (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object { $_.JobState -eq "Transferring" }) {
                Start-Sleep -Seconds 2
                $AllDownloads = Get-BitsTransfer -Name "Podcast"
                $AllBytesTransferred = ($AllDownloads | Measure-Object -Property BytesTransferred -Sum).Sum
                $AllBytesTotal = ($AllDownloads | Measure-Object -Property BytesTotal -Sum).Sum
                $PercentComplete = ($AllBytesTransferred/$AllBytesTotal)*100 -as [int32]

                If (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object {($_.JobState -eq "Transferring")}) {
                    Write-Progress -Activity "Downloading $($MediaFileUrl.Count) Podcast File(s); Total Size : $InitialBytesTotal MB" `
                    -Status "$PercentComplete % downloaded" -PercentComplete $PercentComplete

                }
                If (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object {($_.JobState -eq "Transferred")}) {
                    $DownloadsComplete = Get-BitsTransfer -Name "Podcast" | Where-Object {($_.JobState -eq "Transferred")}
                    Foreach ($DownloadComplete in $DownloadsComplete) {
                        Write-Output "Download of file $($DownloadComplete.FileList.LocalName) complete"
                        $DownloadComplete | Complete-BitsTransfer
                    }
                }
                If (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object {($_.JobState -eq "Error")}) {
                    $DownloadErrors = Get-BitsTransfer -Name "Podcast" | Where-Object {($_.JobState -eq "Error")}
                    Foreach ($DownloadError in $DownloadErrors) {
                        Write-Error "The download of $($DownloadError.FileList.RemoteName) has failed"
                        Write-Error "$DownloadError.ErrorDescription"
                        $DownloadError | Remove-BitsTransfer
                    }
                }
            }
        }      
        Else {
            # Deriving parameters to call Get-Podcast from the parameters bound to Save-Podcast
            If ($PSBoundParameters.ContainsKey("Destination")) {
                $PSBoundParameters.Remove("Destination") | Out-Null
            }            

            $FilesToDownload = Get-Podcast @PSBoundParameters | Select-Object -ExpandProperty MediaFileUrl

            Foreach ($FileToDownload in $FilesToDownload) {
                Write-Debug "`$FileToDownload : $FileToDownload "

                $MediaFileName = ($FileToDownload -split '/')[-1]
                Write-Debug "`$MediaFileName : $MediaFileName "

                If (-not ($Destination)) {
                    # Downloading to the current directory by default
                    $OutFile = Join-Path -Path $PWD -ChildPath $MediaFileName
                }
                Else {
                    $OutFile = Join-Path -Path $Destination -ChildPath $MediaFileName
                }
                Write-Debug "`$OutFile : $OutFile "

                # Using the parameter -Asynchronous to allow downloading multiple files in parallel
                $Job = Start-BitsTransfer -DisplayName "Podcast" -Source $FileToDownload -Destination $OutFile -Asynchronous -Priority Foreground -RetryInterval 60
                
                # Waiting just a little bit to check if the connection to the URL fails
                Start-Sleep -Seconds 1
                    
                # Error handling : Try/Catch doesn't work because it is a background job
                If ($Job.JobState -eq "Error") {
                    Write-Error "The download of $($Job.FileList.RemoteName) has failed. `r`n$($Job.ErrorDescription) "
                    $Job | Remove-BitsTransfer
                    Continue
                }                       
            }
            # Waiting for all jobs to start before calculating the total download size
            While (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object { $_.JobState -eq "Connecting" }) {
                Start-Sleep -Milliseconds 100
            }
            [int]$InitialBytesTotal = ((Get-BitsTransfer -Name "Podcast" | Measure-Object -Property BytesTotal -Sum).Sum)/1MB

            While (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object { $_.JobState -eq "Transferring" }) {
                Start-Sleep -Seconds 2
                $AllDownloads = Get-BitsTransfer -Name "Podcast"
                $AllBytesTransferred = ($AllDownloads | Measure-Object -Property BytesTransferred -Sum).Sum
                $AllBytesTotal = ($AllDownloads | Measure-Object -Property BytesTotal -Sum).Sum
                $PercentComplete = ($AllBytesTransferred/$AllBytesTotal)*100 -as [int32]

                If (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object {($_.JobState -eq "Transferring")}) {
                    Write-Progress -Activity "Downloading $($FilesToDownload.Count) Podcast File(s); Total Size : $InitialBytesTotal MB" `
                    -Status "$PercentComplete % downloaded" -PercentComplete $PercentComplete

                }
                If (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object {($_.JobState -eq "Transferred")}) {
                    $DownloadsComplete = Get-BitsTransfer -Name "Podcast" | Where-Object {($_.JobState -eq "Transferred")}
                    Foreach ($DownloadComplete in $DownloadsComplete) {
                        Write-Output "Download of file $($DownloadComplete.FileList.LocalName) complete"
                        $DownloadComplete | Complete-BitsTransfer
                    }
                }
                If (Get-BitsTransfer -Name "Podcast" -ErrorAction SilentlyContinue | Where-Object {($_.JobState -eq "Error")}) {
                    $DownloadErrors = Get-BitsTransfer -Name "Podcast" | Where-Object {($_.JobState -eq "Error")}
                    Foreach ($DownloadError in $DownloadErrors) {
                        Write-Error "The download of file $($DownloadError.FileList) has failed"
                        Write-Error "$DownloadError.ErrorDescription"
                        $DownloadError | Remove-BitsTransfer
                    }
                }
            }
        }
    }
    End {   
        If ( $BITSWasStopped ) {
            Write-Verbose "Stopping BITS"            
            Stop-Service -Name BITS
        }
    }
}

function Add-PodcastToList {
<#
.SYNOPSIS
    Adds one or more podcast URL(s) to a file.
    This file can later be used as input for the cmdlets Get-Podcast and Save-Podcast.

.DESCRIPTION
    Appends one or more podcast URL(s) to a file.
    If the specified file doesn't exist, it creates the file.
    This file act as a podcast list and it can later be used as input for the cmdlets Get-Podcast and Save-Podcast.

.PARAMETER List
    The full path to the text file listing the RSS/Atom URLs of podcasts.
    The file stores one podcast URL per line.

.EXAMPLE
    Add-PodcastToList -Url "http://feeds.feedburner.com/RunasRadio" -List "C:\Documents\Mypodcasts.txt"
    
    Appends the URL "http://feeds.feedburner.com/RunasRadio" to the file Mypodcasts.txt.

.EXAMPLE
    Get-Podcast ".\AudioPodcasts.txt" | Where-Object { $_.Summary -like "*scripting*" } |
    Add-PodcastToList ".\FavoritePodcasts.txt"

    Gets podcast information from the list AudioPodcasts.txt, filters the podcasts of interest and adds them to the list FavoritePodcasts.txt .

#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias("PodcastUrl")]
        [string[]]$Url,

        [Parameter(Position=1,Mandatory=$True)]
        [string]$List
    )
    Begin {  
        If ( -not(Test-Path -Path $List)) {
            New-Item -ItemType file -Path $List

            # Variable to track the content the $List, to avoid adding the same URL twice to the file
            [string[]]$CurrentListContent = @()
        }
        Else {
            # Variable to track the content the $List, to avoid adding the same URL twice to the file
            $CurrentListContent = Get-Content -Path $List
        }
    }
    Process {
        Foreach ( $PodcastURL in $Url ) {
            $TrimmedPodcastURL = $PodcastURL.Trim()
            Write-Debug "Trimmed PodcastURL : $TrimmedPodcastURL "

            If (-not [string]::IsNullOrWhiteSpace($TrimmedPodcastURL)) {

                If ($TrimmedPodcastURL -notin $CurrentListContent) {
                    # The comma is not a typo, this makes sure $PodcastURL is added as a new item in the array
                    $CurrentListContent += ,$TrimmedPodcastURL
                    Write-Debug "CurrentListContent : $CurrentListContent "

                    "`n$TrimmedPodcastURL`n" | Out-File -FilePath $List -Append
                }
            }
        }
    }
    End {
    }
}

function Remove-PodcastFromList {
<#
.SYNOPSIS
    Removes one or more podcast URL(s) from a podcast list file.

.DESCRIPTION
    Removes one or more podcast URL(s) from a file containing podcast URL(s).
    The file must exist and contain podcast URL(s), one per line.
    This file act as a podcast list and it can later be used as input for the cmdlets Get-Podcast and Save-Podcast.

.PARAMETER List
    The full path to the text file listing the RSS/Atom URLs of podcasts.
    The file must exist and contain podcast URL(s), one per line.

.EXAMPLE
    Remove-PodcastFromList -Url "http://feeds.feedburner.com/RunasRadio" -List "C:\Documents\Mypodcasts.txt"
    
    Removes the line containing the URL "http://feeds.feedburner.com/RunasRadio" from the file Mypodcasts.txt.

.EXAMPLE
    Get-Podcast ".\AudioPodcasts.txt" | Where-Object { $_.Summary -like "*scripting*" } |
    Remove-PodcastFromList ".\FavoritePodcasts.txt"

    Gets podcast information from the list AudioPodcasts.txt, filters the podcasts, and removes them from the list FavoritePodcasts.txt .
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Position=0,Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [Alias("PodcastUrl")]
        [string[]]$Url,

        [Parameter(Position=1,Mandatory=$True)]
        [ValidateScript({ Test-Path -Path $_ -Type Leaf })]
        [string]$List
    )
    Begin { 
        # Variable to track the content the $List, to avoid adding the same URL twice to the file 
        $CurrentListContent = Get-Content -Path $List
    }
    Process {
        Foreach ( $PodcastURL in $Url ) {
            $TrimmedPodcastURL = $PodcastURL.Trim()
            Write-Debug "Trimmed PodcastURL : $TrimmedPodcastURL "

            If ($TrimmedPodcastURL -in $CurrentListContent) {
                # The comma is not a typo, this makes sure $PodcastURL is added as a new item in the array
                $CurrentListContent -= $TrimmedPodcastURL
                Write-Debug "CurrentListContent : $CurrentListContent "

                "`n$TrimmedPodcastURL`n" | Out-File -FilePath $List -Append
            }
        }
    }
    End {
    }
}
