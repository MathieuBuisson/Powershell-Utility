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

.PARAMETER InputFile
    To specify the path to a text file containing the RSS/Atom URLs of podcasts to query. One podcast URL per line.

.PARAMETER FromLastDays
    To retrieve only the podcast episodes newer than the specified number of days ago

.PARAMETER Last
    To specify how many of the latest episodes you want to retrieve, for each podcast.

.EXAMPLE
    Get-Podcast -InputFile C:\Documents\Mypodcasts.txt -Last 1
    To get the last episode for each podcast listed in the file Mypodcasts.txt .

.EXAMPLE
    Get-Podcast -Url http://feeds.feedburner.com/PowerScripting -FromLastDays 30
    To get the episodes from the last 30 days of the PowerScripting podcast.
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Position=0,
                   ValueFromPipeline=$True,
                   HelpMessage="One or more RSS/Atom feed URLs to query for podcasts information",
                   ParameterSetName='Url')]
        [string[]]$Url,
        
        [Parameter(Position=0,
                   ParameterSetName='InputFile')]
        [validatescript({ Test-Path $_ })]
        [string]$InputFile,

        [int]$FromLastDays = 30,

        [int]$Last = 99
    )

    Begin {
        If ($InputFile) {
            $Url = Get-Content $InputFile
        }
        $PublishedFromDate = (Get-Date).AddDays(-$FromLastDays)
        Write-Verbose "`$PublishedFromDate : $PublishedFromDate ."        
        
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
    }
    Process {
        foreach ( $PodcastURL in $Url ) {
            [xml]$PodcastFeed = Invoke-WebRequest -Uri $PodcastURL
            $PodcastFeedItems = $PodcastFeed.rss.channel.Item
            $PodcastTitle = $PodcastFeed.rss.channel.title

            # Initializing a counter variable for each podcast
            $EpisodeCount = 0
            Write-Verbose "`$EpisodeCount is : $EpisodeCount ."

            # Avoiding useless looping if the podcast feed contains less episodes than the value of $Last
            if ( $PodcastFeedItems.count -le $Last ) {
                $Last = $PodcastFeedItems.count
            }
            Write-Verbose "`$Last : $Last ."
             
            foreach ( $PodcastFeedItem in $PodcastFeedItems ) {
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
                
                if ($PodcastEpisodeObj.PublishedDate -ge $PublishedFromDate) {
                    Write-Output $PodcastEpisodeObj
                }
                # Incrementing the counter variable each time we go through the while loop
                $EpisodeCount += 1
                Write-Verbose "`$EpisodeCount : $EpisodeCount ."

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

.PARAMETER InputFile
    To specify the path to a text file containing the RSS/Atom URLs of podcasts. One podcast URL per line.

.PARAMETER MediaFileUrl
    To specify one or more mediafiles to download by entering their direct URL.

.PARAMETER FromLastDays
    To download only the podcast episodes newer than the specified number of days ago

.PARAMETER Last
    To specify how many of the latest episodes you want to download, for each podcast.

.PARAMETER Destination
    To specify the destination folder where to save the podcast files

.EXAMPLE
    Save-Podcast -InputFile C:\Documents\Mypodcasts.txt -Last 1 -Destination $env:USERPROFILE\desktop
    To download the last episode for each podcast listed in the file Mypodcasts.txt to the desktop.

.EXAMPLE
    Save-Podcast -Url http://feeds.feedburner.com/PowerScripting -FromLastDays 30
    To download the episodes from the last 30 days of the PowerScripting podcast to the current directory.

.EXAMPLE
    Get-Podcast -InputFile C:\Documents\Mypodcasts.txt -Last 1 | Save-Podcast
    To download the last episode for each podcast listed in the file Mypodcasts.txt, using pipeline input.
#>
    [CmdletBinding()]
    
    Param(
        [Parameter(Position=0,
                   ParameterSetName='Url')]
        [string[]]$Url,
        
        [Parameter(Position=0,
                   ParameterSetName='InputFile')]
        [validatescript({ Test-Path $_ })]
        [string]$InputFile,

        [Parameter(Position=0,
                   ValueFromPipelineByPropertyName=$True,
                   ParameterSetName='MediaFileUrl')]
        [string[]]$MediaFileUrl,

        [string]$Destination,

        [int]$FromLastDays = 30,

        [int]$Last = 99
    )

    Begin {        
        If ($InputFile) {
            $Url = Get-Content $InputFile
        }
        $PublishedFromDate = (Get-Date).AddDays(-$FromLastDays)
        Write-Verbose "`$PublishedFromDate : $PublishedFromDate ."
        
        # Clearing the default parameter values in the function's scope
        $PSDefaultParameterValues.Clear()
    }
    Process {
        if ($MediaFileUrl) {
            Foreach ( $MediaFile in $MediaFileUrl ) {
                Write-Verbose "`$MediaFile : $MediaFile "

                $MediaFileName = ($MediaFile -split '/')[-1]
                Write-Verbose "`$MediaFileName : $MediaFileName "

                if (-not ($Destination)) {
                    # Downloading to the current directory by default
                    $OutFile = Join-Path -Path $PWD -ChildPath $MediaFileName
                }
                Else {
                    $OutFile = Join-Path -Path $Destination -ChildPath $MediaFileName
                }
                Write-Verbose "`$OutFile : $OutFile "

                Invoke-WebRequest -Uri $MediaFile -OutFile $OutFile
                write-Output "Downloaded the media file : $MediaFile to $OutFile "
            }
        }      
        Else {

            foreach ( $PodcastURL in $Url ) {
                [xml]$PodcastFeed = Invoke-WebRequest -Uri $PodcastURL
                $PodcastFeedItems = $PodcastFeed.rss.channel.Item
                $PodcastTitle = $PodcastFeed.rss.channel.title

                # Initializing a counter variable for each podcast
                $EpisodeCount = 0
                Write-Verbose "`$EpisodeCount is : $EpisodeCount ."

                # Avoiding useless looping if the podcast feed contains less episodes than the value of $Last
                if ( $PodcastFeedItems.count -le $Last ) {
                    $Last = $PodcastFeedItems.count
                }
                Write-Verbose "`$Last : $Last ."
             
                foreach ( $PodcastFeedItem in $PodcastFeedItems ) {
                    $CustomProps = [ordered]@{'PodcastTitle'=$PodcastTitle
                                              'PodcastUrl'=$PodcastURL
                                              'Title'=$PodcastFeedItem.Title
                                              'Summary'=$PodcastFeedItem.Summary
                                              'Link'=$PodcastFeedItem.Link
                                              'PublishedDate'=$PodcastFeedItem.pubDate.Substring(0,25) -as [datetime]
                                              'Author'=$PodcastFeedItem.Author
                                              'MediaFileUrl'= $PodcastFeedItem.Enclosure.Url
                                              'MediaFileName'=($PodcastFeedItem.Enclosure.Url -split '/')[-1]}

                    $PodcastEpisodeObj = New-Object -TypeName psobject -Property $CustomProps
           
                    if ($PodcastEpisodeObj.PublishedDate -ge $PublishedFromDate) {
                        $MediaFile = $PodcastEpisodeObj.MediaFileUrl
                        Write-Verbose "`$MediaFile : $MediaFile "

                        $MediaFileName = $PodcastEpisodeObj.MediaFileName
                        Write-Verbose "`$MediaFileName : $MediaFileName "

                        if (-not ($Destination)) {
                            # Downloading to the current directory by default
                            $OutFile = Join-Path -Path $PWD -ChildPath $MediaFileName
                        }
                        Else {
                            $OutFile = Join-Path -Path $Destination -ChildPath $MediaFileName
                        }
                        Write-Verbose "`$OutFile : $OutFile "

                        Invoke-WebRequest -Uri $MediaFile -OutFile $outfile
                        write-Output "Downloaded the media file : $MediaFile to $OutFile "
                    }
                    # Incrementing the counter variable each time we go through the while loop
                    $EpisodeCount += 1
                    Write-Verbose "`$EpisodeCount : $EpisodeCount ."

                    # Breaking out of the Foreach loop to get only the number of latest episodes specified in $Last
                    If ($EpisodeCount -ge $Last) {
                        break
                    }
                }
            }
        }
    }
    End {   
    }
}
