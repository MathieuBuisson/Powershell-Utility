##Description :



This module contains 1 cmdlet : **Update-ChocolateyPackage**.  
It requires PowerShell version 5
 (or later) and local Administrator privileges.



##Update-ChocolateyPackage :




Uses the Powershell 5.0 PackageManagement module to update Chocolatey packages 
to the latest stable version.  
It compares the version currently installed Chocolatey packages on the local 
machine with the latest stable version.  
If the currently installed version is lower than the latest, it installs the 
latest version from the Chocolatey gallery.  
It takes care of uninstalling the previous version if necessary and installing any dependencies.

Currently, the PackageManagement module of PowerShell 5.0 doesn't include a 
Update-Package cmdlet.  
More information : https://github.com/OneGet/oneget/issues/58
So the present function is an alternative.


###Parameters :



**Name :** To specify the name of one or more installed Chocolatey packages which should be updated.  
If not specified, this function will check all the Chocolatey packages currently installed on the local machine.  



**WhatIf :** To check the Chocolatey packages for updates, without actually updating them.  
The output "What if" information is only in the case where a package is not up-to-date.  
No output means that all packages are up-to-date.


###Examples :



-------------------------- EXAMPLE 1 --------------------------

PS C:\>Update-ChocolateyPackage -WhatIf


Checks all the currently installed Chocolatey packages for updates without 
updating them.
The output "What if" information is only for packages which are not up-to-date.




-------------------------- EXAMPLE 2 --------------------------

PS C:\>"putty","winscp","wireshark" | Update-ChocolateyPackage


Checks only the 3 Chocolatey packages specified from the pipeline and for 
those which are not up-to-date,
installs the latest version available from the Chocolatey gallery.

