    <#
.SYNOPSIS
    Converts Mediasite Storage report to QDirStat format
.DESCRIPTION
    Converts Mediasite Storage report to QDirStat format

    Once the report has been converted run :> qdirstat -c <output file>
.PARAMETER report
    Mediasite XML report file
.PARAMETER output
    Output file in QDirStat format
.PARAMETER revisionReport
    Outputs presentation as folder with files representing head,revision and archive using extensions
.PARAMETER storagePerView
    Outputs file size as Size/View 
.PARAMETER LastViewedReport 
    Outputs file size as seconds since last viewed 
.PARAMETER views
    Outputs file size as views
.PARAMETER lastviewed
    Switches to using last viewed date instead of modified date.  Defaults to last viewed in the lastviewreport option
.EXAMPLE
    .\convert.ps1 -report "Mediasite Storage report.xml" -output "qdirstat.out"
    Reading Mediasite report: Mediasite Storage report.xml
    Converting to QDirStat format
    Saving to: qdirstat.out
.NOTES
    QDirStat info can be found here: https://github.com/shundhammer/qdirstat

    It is recommened to add mime setting for .head,.version and .archive 
    along with settings for the views extensions .0,.1,.10,.100....
    This will allow you to set the colors for the graph
    A sample QDirStat-mime.conf has been included or it can by used inplace of the default one
#>

[CmdletBinding(DefaultParameterSetName='default')]
param
(
    [Parameter(ParameterSetName='revisionreport',Mandatory=$True)]
    [Parameter(ParameterSetName='storageperview',Mandatory=$True)]
    [Parameter(ParameterSetName='lastviewedreport',Mandatory=$True)]
    [Parameter(ParameterSetName='views',Mandatory=$True)]
    [Parameter(ParameterSetName='Duration',Mandatory=$True)]
    [Parameter(ParameterSetName='default',Mandatory=$True)][string]$report,
    [Parameter(ParameterSetName='revisionreport',Mandatory=$True)]
    [Parameter(ParameterSetName='storageperview',Mandatory=$True)]
    [Parameter(ParameterSetName='lastviewedreport',Mandatory=$True)]
    [Parameter(ParameterSetName='views',Mandatory=$True)]
    [Parameter(ParameterSetName='Duration',Mandatory=$True)]
    [Parameter(ParameterSetName='default',Mandatory=$True)][string]$output,
    [Parameter(ParameterSetName='revisionreport',Mandatory=$True)][switch]$revisionReport,
    [Parameter(ParameterSetName='storageperview',Mandatory=$True)][switch]$storagePerView,
    [Parameter(ParameterSetName='lastviewedreport',Mandatory=$True)][switch]$LastViewedReport,
    [Parameter(ParameterSetName='lastviewedreport')][int]$daypower=10,
    [Parameter(ParameterSetName='views',Mandatory=$True)][switch]$views,
    [Parameter(ParameterSetName='Duration',Mandatory=$True)][switch]$Duration,
    [switch]$lastviewed
)
#$todayepoc
#$maxdays =0
$script:idtxt = ""
$script:lastfolder = ""
$script:lasttitle = ""
$script:duplicatecnt = 0

$lastviewedoption = ($lastviewed -or $LastViewedReport) 

if($LastViewedReport){
    $script:todayepoc = get-date -UFormat %s
}
function Remove-StringSpecialCharacter {
    <#
.SYNOPSIS
    This function will remove the special character from a string.
.DESCRIPTION
    This function will remove the special character from a string.
    I'm using Unicode Regular Expressions with the following categories
    \p{L} : any kind of letter from any language.
    \p{Nd} : a digit zero through nine in any script except ideographic
    http://www.regular-expressions.info/unicode.html
    http://unicode.org/reports/tr18/
.PARAMETER String
    Specifies the String on which the special character will be removed
.PARAMETER SpecialCharacterToKeep
    Specifies the special character to keep in the output
.EXAMPLE
    Remove-StringSpecialCharacter -String "^&*@wow*(&(*&@"
    wow
.EXAMPLE
    Remove-StringSpecialCharacter -String "wow#@!`~)(\|?/}{-_=+*"
    wow
.EXAMPLE
    Remove-StringSpecialCharacter -String "wow#@!`~)(\|?/}{-_=+*" -SpecialCharacterToKeep "*","_","-"
    wow-_*
.NOTES
    Francois-Xavier Cat
    @lazywinadmin
    lazywinadmin.com
    github.com/lazywinadmin
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Text')]
        [System.String[]]$String,

        [Alias("Keep")]
        #[ValidateNotNullOrEmpty()]
        [String[]]$SpecialCharacterToKeep
    )
    PROCESS {
        try {
            IF ($PSBoundParameters["SpecialCharacterToKeep"]) {
                $Regex = "[^\p{L}\p{Nd}"
                Foreach ($Character in $SpecialCharacterToKeep) {
                    IF ($Character -eq "-") {
                        $Regex += "-"
                    }
                    else {
                        $Regex += [Regex]::Escape($Character)
                    }
                    #$Regex += "/$character"
                }

                $Regex += "]+"
            } #IF($PSBoundParameters["SpecialCharacterToKeep"])
            ELSE { $Regex = "[^\p{L}\p{Nd}]+" }

            FOREACH ($Str in $string) {
                Write-Verbose -Message "Original String: $Str"
                $Str -replace $regex, ""
            }
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    } #PROCESS
}


# Outputs the directories that exist between two directories
# /test /test/dir2/dir3
# ["/test","/test/dir2","/test/dir2/dir3"]
function inbetweendirs{
    param([string]$cdir ,[string]$ndir)
    if($cdir -eq ""){
    }
    if($cdir -ne $ndir){
        $cdirs = $cdir.split('/')
        $ndirs = $ndir.split('/')
        $maxlength = [math]::min($ndirs.Length,$cdirs.length)
   
        $newdir = ""
        for($j=0;$j -lt $maxlength;$j++){
            if($cdirs[$j] -eq $ndirs[$j]){
               $newdir = [string]::join('/',$cdirs[0..$j] + @("$($ndirs[$j+1])"))
            }
            elseif($cdir.length -eq $ndir.Length){
                $newdir = [string]::join('/',$ndirs)
            }
        }
        $c = @()
        if($newdir -ne $null){
            $c += $newdir
        }
        [array]$condir =inbetweendirs -cdir $newdir -ndir $ndir 
        if($null -ne $condir){
            $c += $condir
        }
         
        return [array]$c
    }
    else{
    }
}

#Outputs presentation as a directory in the report with head,revision and archive as seperat files with respective file extensions
function PresentationLineRevisions{
    param
    (
        $presenation,
        [string]$folder
        
    )
    $datehex='0x{0:X8}' -f [INT]([Math]::Floor([decimal](Get-Date([datetime]$presentation.LastModified).ToUniversalTime()-uformat "%s")))
    
    $Titlenew = $presentation.Title.replace('/',"_")
    $Titlenew = (Remove-StringSpecialCharacter -string $Titlenew -keep "-"," ","(",")",".","_") + $ext
    $Titlenew = $Titlenew.replace(' ',"%20")
    
    $pdir = $folder + "/" + $Titlenew
    $dirtxt = ""
    #$dirtxt += ("`nD $($pdir.Replace(' ','%20'))     4096    $datehex`n")
    $dirtxt += ("`nD $($pdir.Replace(' ','%20'))     0    $datehex`n")
    #$dirtxt += ("`nD $($pdir.Replace(' ','%20'))     1    $datehex`n")
    
    if([long]$presentation.TotalHeadRevisionStorage -gt 0){
        $dirtxt += "F`t$Titlenew.Head`t$($presentation.TotalHeadRevisionStorage)`t$datehex`n"
    }
    if([long]$presentation.TotalIntermediateRevisionStorage -gt 0){
        $dirtxt += "F`t$Titlenew.Revision`t$($presentation.TotalIntermediateRevisionStorage)`t$datehex`n"
    }
    if([long]$presentation.TotalArchiveRevisionStorage -gt 0){
        
        $dirtxt += "F`t$Titlenew.Archive`t$($presentation.TotalArchiveRevisionStorage)`t$datehex`n"
    }
    return $dirtxt
}



#Outputs presentation as a file with extension based on views
function PresentationLine{
    param
    (
        $presenation,
        [string]$folder
        
    )
    if($lastviewedoption){
        $LastViewed =  $presentation.LastViewed
        if($LastViewed -eq "-"){
            $LastViewed = $presentation.Recorded
        }
        if($LastViewed -eq "-"){
            $LastViewed = $presentation.LastModified
        }
        $LastModified = [datetime]$LastViewed
    }
    else{
        $LastModified = [datetime]$presentation.LastModified
    }
    $datehex='0x{0:X8}' -f [INT]([Math]::Floor([decimal](Get-Date($LastModified[0]).ToUniversalTime()-uformat "%s")))
    
    if($storagePerView){
        $t = $presentation.TotalViews
        if($t -eq 0){
            $t = .1
        }
        $Total = [long]($presentation.TotalStorage / $t)
    }
    elseif($LastViewedReport){
        
        #write-host $script:todayepoc - (get-date -Date $LastViewed -UFormat %s) =  ([Math]::Floor(($script:todayepoc - (get-date -Date $LastViewed -UFormat %s)) /86400))
        #$Total = [Math]::Floor($script:todayepoc - (get-date -Date $LastViewed -UFormat %s))
        #$Total = [math]::log($Total) 
        #write-host $Total ([math]::Floor([math]::log($Total))) ([math]::Floor(([math]::pow($Total,5) -as [long])))
        #$Total = [math]::pow($Total,2)
        #$Total = ([math]::Floor(([math]::pow($Total,5) -as [long])))
        $Total = ($script:todayepoc - (get-date -Date $LastViewed -UFormat %s)) /86400
        #$script:maxdays = [math]::Max($Total,$script:maxdays)
        if($daypower -ne 1){
            $Total = $Total /365
            #write-host "taking $daypower power of days since last viewed to emphasize"
        }
        $Total = [math]::Floor([math]::pow($Total,$daypower))
        #write-host "maxdays:$script:maxdays"
        #$datehex='0x{0:X8}' -f [INT]([Math]::Floor([decimal](Get-Date([datetime]$LastViewed).ToUniversalTime()-uformat "%s")))
    }
    elseif($Duration){
        $Total = [long]$presentation.Duration
    }
    elseif($views){
        $Total = [long]$presentation.TotalViews #* 1024
        #write-host ([long]$presentation.TotalViews) * 1024 = $Total
    }
    else{
        $Total=[long]$presentation.TotalStorage  
    }
    $Titlenew = $presentation.Title
    $ext = ".10000"
    $tviews = [long]$presentation.TotalViews
    if($tviews -eq 0){
        $ext = ".0"
    }
    elseif($tviews -lt 10){
        $ext = ".1"
    }
    elseif($tviews -lt 100){
        $ext = ".10"
    }
    elseif($tviews -lt 200){
        $ext = ".100"
    }
    elseif($tviews -lt 300){
        $ext= ".200"
    }
    elseif($tviews -lt 400){
        $ext= ".300"
    }
    elseif($tviews -lt 500){
        $ext= ".400"
    }
    elseif($tviews -lt 600){
        $ext= ".500"
    }
    elseif($tviews -lt 700){
        $ext= ".600"
    }
    elseif($tviews -lt 800){
        $ext= ".700"
    }
    elseif($tviews -lt 900){
        $ext= ".800"
    }
    elseif($tviews -lt 1000){
        $ext= ".900"
    }
    elseif($tviews -lt 1100){
        $ext = ".1000"
    }
    elseif($tviews -lt 1200){
        $ext = ".1100"
    }
    elseif($tviews -lt 1300){
        $ext = ".1200"
    }
    elseif($tviews -lt 1400){
        $ext = ".1300"
    }
    elseif($tviews -lt 1500){
        $ext = ".1400"
    }
    elseif($tviews -lt 1600){
        $ext = ".1500"
    }
    
    if($Titlenew -eq $script:lasttitle){
    }
    if(($Titlenew -eq $script:lasttitle) -and ($folder -eq $script:lastfolder)){
        write-host "duplicate: $Titlenew"
        write-host "folders: $folder`n       : $script:lastfolder"
        $script:duplicatecnt++
        $ext = "_" + $script:duplicatecnt + $ext
        write-host "duplicate title $ext"
    }
    else{
        $script:duplicatecnt = 0       
    }
$script:lastfolder = $folder
$script:lasttitle = $Titlenew

    $Titlenew = $Titlenew.replace('/',"_")
    $Titlenew = (Remove-StringSpecialCharacter -string $Titlenew -keep "-"," ","(",")",".","_")
    $Titlenew = $Titlenew.replace(' ',"%20")
    #write-host $Titlenew $Total $tviews $ext
    $folder =  $folder.Replace('%20',' ')
    if($Folder[-1] -eq '/'){
        $script:idtxt += "$($presentation.Id),$Folder$($Titlenew.replace('%20',' '))$ext,`n"
    }
    else{
        $script:idtxt += "$($presentation.Id),$Folder/$($Titlenew.replace('%20',' '))$ext,`n"
    }
    
#$script:duplicatecnt = 0

    return "F`t$Titlenew$ext`t$Total`t$datehex`n"
}

$previousFolder = ""
function Directories($presentation){
    #$newfolder = ""
    #$curretd = ""
    
    if($script:previousFolder -ne $presentation.Folder){
        $filldirs = inbetweendirs -cdir $script:previousFolder -ndir $presentation.Folder 
        $script:previousFolder = $presentation.Folder
        $dirtxt = ""
        
        foreach($d in $filldirs){
            #$dirtxt += ("`nD $($d.Replace(' ','%20'))     4096    0x5a21d1e7`n")
            $dirtxt += ("`nD $($d.Replace(' ','%20'))     0    0x5a21d1e7`n")
            #$dirtxt += ("`nD $($d.Replace(' ','%20'))     1    0x5a21d1e7`n")
        #    $currentd = $d
        }
        if($revisionReport){
            return ($dirtxt + (PresentationLineRevisions -presentation $presentation -folder $script:previousFolder))
        }
        else{
            return ($dirtxt + (PresentationLine -presentation $presentation -folder $script:previousFolder))
        }
    }
    if($revisionReport){
        return ("" + (PresentationLineRevisions -presentation $presentation -folder $script:previousFolder))
    }
    else{
        return ("" + (PresentationLine -presentation $presentation -folder $script:previousFolder))   
    }
}

function OutputFile($presentations){
$header=
@'
[qdirstat 1.0 cache file]
# Generated by qdirstat-cache-writer
# Do not edit!
#
# Type  path            size    mtime           <optional fields>
'@
$text2=$header

foreach ($p in $presentations) { $text2 += Directories($p) }
return $text2
}

write-host "Reading Mediasite report: $report"
[xml]$xmlpsych = Get-Content -Path $report
write-host "Sorting report by folder"
$sorted = $xmlpsych.MediasiteReport.Presentations.Presentation | Sort-Object -Property Folder,Title

write-host "Converting to QDirStat format"
$tout = OutputFile($sorted)
write-host "Saving to: $output"
$tout | Out-File -FilePath $output -Encoding Ascii
write-host "Saving idmap.txt"
#$script:idtxt | Out-File -FilePath ($output + ".idmap") -Encoding Ascii
$script:idtxt | Out-File -FilePath "idmap.txt" -Encoding Ascii