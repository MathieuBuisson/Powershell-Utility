##Description :

This module contains one cmdlet : **Compare-FolderFiles**.

It compares the files in one folder with the files in another folder.  
Uses a MD5 hash value to uniquely identify and compare the content of the files.

Requires Powershell version 4.

##Parameters :

**ReferenceFolder :** Folder used as a reference for comparison. The command checks that the value for this parameter is a valid path.

**DifferenceFolder :** Specifies the folder that is compared to the reference folder.  
Accepts pipeline input, and the command checks that the value for this parameter is a valid path.

**Recurse :** Compares all files in the Reference folder and difference folder, including their child folders. 

**Force :** Includes the hidden files and hidden child folders.

**ShowDifferenceSide :** Shows only the different files which are located in the difference folder.

**ShowReferenceSide :** Shows only the different files which are located in the reference folder.

**ShowNewer :** For files with the same name which exist in the same location in the reference folder and the difference folder (but have different hash values), this shows only the newer version of the file.
