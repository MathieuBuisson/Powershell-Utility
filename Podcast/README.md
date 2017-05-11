## Description :

This module contains 4 cmdlets :  
  - **Get-Podcast**  
  - **Save-Podcast**  
  - **Add-PodcastToList**  
  - **Remove-PodcastFromList**  

It requires PowerShell version 4 (or later).


## Get-Podcast :

Retrieves information on podcast(s) episodes from the podcast RSS/Atom feed(s) specified in the 
-Url parameter or from a file.

### Parameters :

**Url :** RSS/Atom feed URLs to query for podcasts information.  

Can take a comma-separated list of URLs.  

**List :** To specify the path to a text file listing the RSS/Atom URLs of podcasts to query.  

The file should contain one podcast URL per line.  

**FromLastDays :** To retrieve only the podcast episodes newer than the specified number of days ago.  

The default is 365 days.  
**Last :** To specify how many of the latest episodes you want to retrieve, for each podcast.  

If the user specifies both -FromLastDays and -Last parameters, -FromLastDays takes precedence.
  
This means that if the last episode of a given podcast is older than the number of days specified with -FromLastDays, no episode will be ouput for this podcast, regardless of the value of the -Last parameter.  
If not specified, it defaults to 99 .

### Examples :

-------------------------- EXAMPLE 1 --------------------------

C:\PS>Get-Podcast -List C:\Documents\Mypodcasts.txt -Last 1


To get the last episode for each podcast listed in the file Mypodcasts.txt .




-------------------------- EXAMPLE 2 --------------------------

C:\PS>Get-Podcast -Url http://feeds.feedburner.com/PowerScripting -FromLastDays 30


To get the episodes from the last 30 days of the PowerScripting podcast.




-------------------------- EXAMPLE 3 --------------------------

C:\PS>"http://feeds.feedburner.com/RunasRadio","http://feeds.feedburner.com/PowerScripting" | Get-Podcast -Last 2  

To get the last 2 episodes from the podcasts URLs input from the pipeline.






## Save-Podcast :

Downloads podcast(s) episodes from the podcast RSS/Atom feed(s) specified in the -Url parameter 
or from a file.  
It can also take the podcast objects piped from Get-Podcast.

### Parameters :

**Url :** RSS/Atom feed Url for the podcasts to query for download.  

Can take a comma-separated list of URLs.  

**List :** To specify the path to a text file listing the RSS/Atom URLs of podcasts.  

The file should contain one podcast URL per line.  

**MediaFileUrl :** To specify one or more mediafiles to download by entering their direct URL.  

**Destination :** To specify the destination folder where to save the podcast files  

**FromLastDays :** To download only the podcast episodes newer than the specified number of days ago.  

The default is 365 days.  
**Last :** To specify how many of the latest episodes you want to download, for each podcast.  

If the user specifies both -FromLastDays and -Last parameters, -FromLastDays takes precedence.  

This means that if the last episode of a given podcast is older than the number of days specified with -FromLastDays, no episode will be ouput for this podcast, regardless of the value of the -Last parameter.  
If not specified, it defaults to 99 .

### Examples :

-------------------------- EXAMPLE 1 --------------------------

C:\PS>Save-Podcast -List C:\Documents\Mypodcasts.txt -Last 1 -Destination $env:USERPROFILE\desktop


To download the last episode for each podcast listed in the file Mypodcasts.txt to the desktop.




-------------------------- EXAMPLE 2 --------------------------

C:\PS>Save-Podcast -Url http://feeds.feedburner.com/PowerScripting -FromLastDays 30


To download the episodes from the last 30 days of the PowerScripting podcast to the current 
directory.




-------------------------- EXAMPLE 3 --------------------------

C:\PS>Get-Podcast -List C:\Documents\Mypodcasts.txt -Last 1 | Save-Podcast


To download the last episode for each podcast listed in the file Mypodcasts.txt, using pipeline 
input.  

## Add-PodcastToList :


Appends one or more podcast URL(s) to a file.  
If the specified file doesn't exist, it creates the file.  
This file act as a podcast list and it can be used as input for the cmdlets Get-Podcast and 
Save-Podcast.

### Parameters :

**Url :** RSS/Atom feed Url of the podcast(s).
Can take a comma-separated list of URLs.
  
It has an alias : PodcastUrl.  

**List :** The full path to the text file listing the RSS/Atom URLs of podcasts.  

The file stores one podcast URL per line.  

### Examples :

-------------------------- EXAMPLE 1 --------------------------

C:\PS>Add-PodcastToList -Url "http://feeds.feedburner.com/RunasRadio" -List "C:\Documents\Mypodcasts.txt"


Appends the URL "http://feeds.feedburner.com/RunasRadio" to the file Mypodcasts.txt.




-------------------------- EXAMPLE 2 --------------------------

C:\PS>Get-Podcast ".\AudioPodcasts.txt" | Where-Object { $_.Summary -like "*scripting*" } | Add-PodcastToList ".\FavoritePodcasts.txt"  

Gets podcast information from the list AudioPodcasts.txt, filters the podcasts of interest and 
adds them to the list FavoritePodcasts.txt .








## Remove-PodcastFromList :

Removes one or more podcast URL(s) from a file containing podcast URL(s).  
The file must exist and contain podcast URL(s), one per line.  
This file act as a podcast list and it can be used as input for the cmdlets Get-Podcast and 
Save-Podcast.

### Parameters :

**Url :** RSS/Atom feed Url of the podcast(s).
Can take a comma-separated list of URLs.  

It has an alias : PodcastUrl.  

**List :** The full path to the text file listing the RSS/Atom URLs of podcasts.
  
The file must exist and contain podcast URL(s), one per line.  

### Examples :

-------------------------- EXAMPLE 1 --------------------------

C:\PS>Remove-PodcastFromList -Url "http://feeds.feedburner.com/RunasRadio" -List "C:\Documents\Mypodcasts.txt"


Removes the line containing the URL "http://feeds.feedburner.com/RunasRadio" from the file 
Mypodcasts.txt.




-------------------------- EXAMPLE 2 --------------------------

C:\PS>Get-Podcast ".\AudioPodcasts.txt" -Last 1 | Where-Object { $_.PublishedDate -lt 
(Get-Date).AddMonths(-3) } |  
Remove-PodcastFromList ".\AudioPodcasts.txt"  

Gets the last episode of each podcast in the list AudioPodcasts.txt, filters the podcasts for 
which the last episode is older than 3 months ago, and removes them from the list.

