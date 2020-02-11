[CmdletBinding()]
param
(
    [string]$path,
    [switch]$nobrowser
)
write-host $path

$idmap = Import-csv .\idmap.txt -Header 'Id','Presentation'

$PreId = ($idmap | where { $_.Presentation -eq $path}).Id

$site = "https://mediasite.csom.umn.edu/mediasite"
$mpath = "/manage#module=Sf.Manage.PresentationSummary&args[id]="

#$arc = Import-Csv .\archive.id -Header 'Id','Presentation'

#"Id,Presentation" | out-file -filepath ".\archive.id" -Encoding unicode
#clear-content -Path ".\archive.id" 
$url = $site + $mpath + $PreId
write-host $url
if(-not $nobrowser){
  Start-Process $url
}

#foreach ($a in $arc) { 
#	write-host $a.Id
#	write-host Presentations -id `"$($a.Id)`" -tags -post -data @{"Tag"="ArchiveDelete"}
#
#}