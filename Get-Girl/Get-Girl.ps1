#Requires -Version 2
# Tested with Powershell 3.0 and Powershell 2.0 (for more traditional girls)

$Me = Whoami /all

# Cautious error handling, I don't want to embarrass myself
$ErrorActionPreference = "Stop"

# Filtering for girls within a reasonable age bracket and not taller than me, NO WAY
$PossibleMatches = Get-People -ListAvailable | Where {$_.Sexe -eq "Female"} | Where {$_.Age -gt ($Me.Age - 6) } |
Where {$_.Age -le ($Me.age  + 3) } | Where {$_.Height -lt ($me.Height) }

# Her smile is the key
$SortedPossibleMatches = $PossibleMatches | Sort -Property Smile -Unique

function Get-Mood {

    param(
        [Parameter(Mandatory=$True)]
        $Person,

        $Clothing,

        [int]$Smiles,

        [boolean]$Drunk
        )

    [int]$Mood = 0

    ForEach ($Smile in $Smiles) {
        $Mood++
    }
    if ($Drunk) {
        $Mood *= 5
    }
    $Mood = $Mood - $Clothing.length
    Write-Output $Mood
}

ForEach ($Her in $SortedPossibleMatches) {
    $Her.Name = Read-Host "Hello, who the heaven are you ??"

    If (($Her.Name -eq "$null") -or ($Her.Name -eq "Leave me alone, douchebag")) {
        Speak-Host "OK, OK." -ErrorAction SilentlyContinue
        Exit
    }
    Else {
        Speak-Host "Lovely to meet you $Her ! I'm $Me."

        $MyMood = Get-Mood -Person $Me -Clothing $Me.Clothing
        $HerSmiles = ($Her | Select -Expand Smiles | Measure).Count
        $HerMood = Get-Mood -Person $Her -Clothing $Her.Clothing -Smiles $HerSmiles

        if (Get-EyeContact -Source $Her -Destination $Me -Quiet) {
            $MyMood++
            $HerMood++
        }
        While (($HerMood -gt 3) -and ($HerMood -le 6)) {
            Invoke-Compliment -Style Witty -Subject $Her

            [int]$number_of_drinks = 0
            [boolean]$Drink = Read-Host "Can I get you a drink ?"
            
            If ($Drink -eq $True) {
                Get-Drink -Type Alcohol -Option straw
                $number_of_drinks++
            }
            $HerMood = $HerMood + $number_of_drinks
        }
        If ( ($HerMood -gt 6 ) -and ($HerMood -ge $MyMood)) {
            Speak-Host -SmallTalk -Verbose
        }
        ElseIf (($HerMood -gt 10 ) -and ($herMood -ge $myMood)) {
            Speak-Host -SmallTalk -Warning

            # Attempting to dance, and handling the most likely ways it can go wrong
            Try {
                Move-Body -Location Dancefloor
            }
            Catch [Body.Articulation.Sprain] {
                # Terminate if I hurt myself trying to dance
                $Excuse = Get-Excuse -Random
                Speak-Host "$Excuse "
                Exit
            }
            Catch [Host.Her.Body.Pain] {
                # Terminate if I hurt her trying to dance
                $Excuse = Get-Excuse -Genuine
                Speak-Host "$Excuse "
                Exit
            }
            Catch [Music.Taste.Exception] {
                # If she shouts "I love that song !" while Daft Punk or Taylor Swift is playing, this is a HUGE no-no
                $Excuse = Get-Excuse -Random
                Speak-Host "$Excuse "
                Exit
            }
            Catch [Drink.Glass.Overflow] {
                # Terminate if I spill my drink on a big dude trying to dance
                $Excuse = Get-Excuse -Wimp
                Speak-Host "$Excuse "
                Exit
            }
            Finally {}
            # If everything goes well up to this point, attempting a kiss
            Try {
                Get-Kiss $Her -Location lips
            }
            Catch [Incoming.Gesture.Slap] {
                Write-Output "Failure"
                Exit
            }
            Finally {
                [Phone]::AddContact($Me.Phone, $Her.Name, $Her.PhoneNumber)
            }
        }
    }
}