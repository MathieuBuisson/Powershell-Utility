##Description :


This module contains 2 cmdlets :  
**Get-Nothing**  
**Set-Nothing**  
It requires PowerShell version 4 (or later).


##Get-Nothing :



This cmdlet does absolutely nothing and does it remarkably well.
It takes objects as input and it outputs nothing.

###Parameters :


**InputObject :** Specifies one or more object(s) to get.
It can be string(s), integer(s), file(s), any type of object.  
If not specified, it defaults to (Get-Item *) .


**Filter :** Specifies a filter in the provider's format or language. The value of this parameter qualifies the InputObject.
The syntax of the filter, including the use of wildcards, or regular expressions, depends on the provider.  


###Examples :


-------------------------- EXAMPLE 1 --------------------------

C:\PS>Get-Nothing -InputObject Item,Thing,Stuff -Filter @{Name -like "*null*"}


Takes the objects Item,Thing and Stuff, filters only the ones with a name containing "null" and 
does nothing.




-------------------------- EXAMPLE 2 --------------------------

C:\PS>Get-Content ".\File.txt" | Get-Nothing


Takes the content of the file File.txt as input and does nothing.








##Set-Nothing :


This cmdlet configures nothing and does it remarkably well.
It takes objects as input and it sets nothing to 42.

###Parameters :


**InputObject :** Specifies one or more object(s) to configure.
It can be string(s), integer(s), file(s), any type of object.  
If not specified, it defaults to (Get-Item *) .


**Value :** Specifies the value to set nothing to.  
If not specified, it defaults to 42 .


###Examples :


-------------------------- EXAMPLE 1 --------------------------

C:\PS>Set-Nothing -InputObject Item,Thing,Stuff -Value $Null


Takes the objects Item,Thing and Stuff, sets nothing to $Null.




-------------------------- EXAMPLE 2 --------------------------

C:\PS>Get-Content ".\File.txt" | Set-Nothing


Takes the content of the file File.txt as input and sets nothing to 42.










