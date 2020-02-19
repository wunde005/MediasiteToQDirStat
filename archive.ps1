[CmdletBinding(DefaultParameterSetName='default')]
param
(
    [string]$tag="testtag",
    [string]$archiveid=".\archive.id"
)

try{
	[array]$arc = Import-Csv $archiveid -Header 'Id','Presentation'
}
catch{
   write-host "archive list missing: $archiveid"
}
$alen = $arc.length
if($alen -lt 1){
	write-verbose "No Id's found"
}
while ($alen -gt 0){
	#$CPreId = $arc[0].Id
	#write-host Presentations -id `"$($arc[0].Id)`" -tags -post -data (Convertto-json(@{"Tag"="ArchiveDelete"}))
	$tagged = Presentations -id $($arc[0].Id) -tags -post -data @{"Tag"=$tag}
	if($tagged.Tag -eq $tag){
		$arc = $arc | Where-Object { $_.Id -ne $arc[0].Id }
		if($null -eq $null){
			write-host "null"
		}
		$alen = $arc.length
		write-host "length" $arc.length $alen
		if($alen -lt 1){
			clear-content -Path $archiveid 	
		}
		else{
			$arc | convertto-csv -NoTypeInformation | ForEach-Object {$_ -replace '"',''} | Select-Object -Skip 1 | Set-Content -Path $archiveid
		}
	}
	else{
		write-host "error?"
		return
	}
	[array]$arc = Import-Csv $archiveid -Header 'Id','Presentation'
	
}
