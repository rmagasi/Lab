########################################################
# Name: ExportImportGPO.ps1
# Creator: Michael Seidl aka Techguy
# CreationDate: 30.11.2013
# LastModified:30.11.2013
# Version: 1.0
# Doc: http://www.techguy.at/tag/exportimportgpo/
#
# Description: This Script Export your GPO to an Folder 
# and create a Subfolder for each GPO. And you can import
# your exported GPO       
#   
# Variables
# ExportFolder: Where to Export your GPO's
# ImportFolder: Where to Import your GPO's
# PreName: Option to add a String at the begining of your GPO Name
# PostName: Option to add a String at the end of your GPO Name
# Version 1.1 - not Published
#        
#
#
# Version 1.0 - RTM
########################################################
#
# www.techguy.at                                        
# www.facebook.com/TechguyAT                            
# www.twitter.com/TechguyAT  
# www.google.com/+TechguyAt                          
# michael@techguy.at 
########################################################


 Param(
   [Parameter(Mandatory=$True)]
   [ValidateSet("Export", "Import")] 
   [string]$Mode #Possible Modes: Export, Import
)
 

import-module grouppolicy
$ExportFolder="C:\temp\GPO\"
$Importfolder="C:\temp\GPO\"
$PreName=""
$PostName=""
 

 function Export-GPOs {
 $GPO=Get-GPO -All
 
 foreach ($Entry in $GPO) {
 $Path=$ExportFolder+$entry.Displayname
 New-Item -ItemType directory -Path $Path
 Backup-GPO -Guid $Entry.id -Path $Path
 }
 }
 

function Import-GPOs {
$Folder=Get-childItem -Path $Importfolder -Exclude *.ps1

foreach ($Entry in $Folder) {
$Name=$PreName+$Entry.Name+$postname
$Path=$Importfolder+$entry.Name
$ID=Get-ChildItem -Path $Path
New-GPO -Name $Name
Import-GPO -TargetName $Name -Path $Path -BackupId $ID.Name
}
}


switch ($Mode){
{$_ -eq "Export"} 
{Export-GPOs
break}

{$_ -eq "Import"} 
{Import-GPOs
break}
}