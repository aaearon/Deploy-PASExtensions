# Deploy-PASExtensions

A collection (eventually!) of Powershell functions that enable continuous delivery of connection component and platform packages for CyberArk's Privileged Account Security solution.

## Update-PASPlatformFiles

A PowerShell function that updates an existing platform's file in the Vault with files from the source path.

Both required platform files (the CPM policy file `Policy-$PlatformId.ini` and the PVWA settings file `Policy-$PlatformId.xml`) must be in the source path. Any other files in the source path will be added to the Vault as long as the platform was imported through the PVWA or the REST API's [Import platform](https://docs.cyberark.com/Product-Doc/OnlineHelp/PAS/Latest/en/Content/WebServices/ImportPlatform.htm?tocpath=Developer%7CREST%20APIs%7CPlatforms%7C_____3) endpoint and the files will be distributed to each CPM's `bin` folder.

### Example

Updates the platform files for all the platforms under C:\Platforms. The platform IDs are assumed from the folder names.

``` powershell
(Get-ChildItem $BasePlatformFolder).FullName | Update-PASPlatformFiles
```
