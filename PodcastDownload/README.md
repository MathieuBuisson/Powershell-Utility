DESCRIPTION :

This Powershell module parses podcast feeds, to look for podcast episodes and if desired, download them.

This module contains 2 cmdlets : Get-Podcast and Save-Podcast.
Save-Podcast can be used on its own, or take pipeline input from Get-Podcast.

It requires Powershell Version 4.

GET-PODCAST :

Retrieves information on podcast(s) episodes from the podcast RSS/Atom feed(s) specified in the -Url parameter or from a file (the file SamplePodcastList can be used as an example).

PARAMETERS :

Url : RSS/Atom feed URLs to query for podcasts information.
Can take a comma-separated list of URLs.

InputFile : To specify the path to a text file containing the RSS/Atom URLs of podcasts to query. One podcast URL per line.

FromLastDays : To retrieve only the podcast episodes newer than the specified number of days ago

Last : To specify how many of the latest episodes you want to retrieve, for each podcast.

SAVE-PODCAST :

Downloads podcast(s) episodes from the podcast RSS/Atom feed(s) specified in the -Url parameter or from a file.
It can also take the podcast objects piped from Get-Podcast.

PARAMETERS :

Same parameters as Get-Podcast, plus :

MediaFileUrl : To specify one or more media files to download by entering their direct URL.

Destination : To specify the destination folder where to save the podcast files. By default, it is the current directory.
