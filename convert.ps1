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
    [Parameter(ParameterSetName='default',Mandatory=$True)][string]$report,
    [Parameter(ParameterSetName='revisionreport',Mandatory=$True)]
    [Parameter(ParameterSetName='storageperview',Mandatory=$True)]
    [Parameter(ParameterSetName='lastviewedreport',Mandatory=$True)]
    [Parameter(ParameterSetName='default',Mandatory=$True)][string]$output,
    [Parameter(ParameterSetName='revisionreport',Mandatory=$True)][switch]$revisionReport,
    [Parameter(ParameterSetName='storageperview',Mandatory=$True)][switch]$storagePerView,
    [Parameter(ParameterSetName='lastviewedreport',Mandatory=$True)][switch]$LastViewedReport
)

if($LastViewedReport){
    $todayepoc = get-date -UFormat %s
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
    $dirtxt += ("`nD $($pdir.Replace(' ','%20'))     4096    $datehex`n")
    
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
function PresentationLine($presentation){
    $LastModified = [datetime]$presentation.LastModified
    $datehex='0x{0:X8}' -f [INT]([Math]::Floor([decimal](Get-Date($LastModified[0]).ToUniversalTime()-uformat "%s")))
    
    $t = $presentation.TotalViews
    if($t -eq 0){
        $t = .1
    }
    
    if($storagePerView){
        $Total = [long]($presentation.TotalStorage / $t)
    }
    elseif($LastViewedReport){
        $LastViewed =  $presentation.LastViewed
        if($LastViewed -eq "-"){
            $LastViewed = $presentation.Recorded
        }
        if($LastViewed -eq "-"){
            $LastViewed = $presentation.LastModified
        }
        $Total = [Math]::Floor($global:todayepoc - (get-date -Date $LastViewed -UFormat %s))
        $datehex='0x{0:X8}' -f [INT]([Math]::Floor([decimal](Get-Date([datetime]$LastViewed).ToUniversalTime()-uformat "%s")))
    }
    else{
        $Total=$presentation.TotalStorage  
    }
    $Titlenew = $presentation.Title
    $ext = ".10000"
    if($presentation.TotalViews -eq 0){
        $ext = ".0"
    }
    elseif($presentation.TotalViews -lt 10){
        $ext = ".1"
    }
    elseif($presentation.TotalViews -lt 100){
        $ext = ".10"
    }
    elseif($presentation.TotalViews -lt 200){
        $ext = ".100"
    }
    elseif($presentation.TotalViews -lt 300){
        $ext= ".200"
    }
    elseif($presentation.TotalViews -lt 400){
        $ext= ".300"
    }
    elseif($presentation.TotalViews -lt 500){
        $ext= ".400"
    }
    elseif($presentation.TotalViews -lt 600){
        $ext= ".500"
    }
    elseif($presentation.TotalViews -lt 700){
        $ext= ".600"
    }
    elseif($presentation.TotalViews -lt 800){
        $ext= ".700"
    }
    elseif($presentation.TotalViews -lt 900){
        $ext= ".800"
    }
    elseif($presentation.TotalViews -lt 1000){
        $ext= ".900"
    }
    elseif($presentation.TotalView -lt 1100){
        $ext = ".1000"
    }
    elseif($presentation.TotalView -lt 1200){
        $ext = ".1100"
    }
    elseif($presentation.TotalView -lt 1300){
        $ext = ".1200"
    }
    elseif($presentation.TotalView -lt 1400){
        $ext = ".1300"
    }
    elseif($presentation.TotalView -lt 1500){
        $ext = ".1400"
    }
    elseif($presentation.TotalView -lt 1600){
        $ext = ".1500"
    }
    
    $Titlenew = $Titlenew.replace('/',"_")
    $Titlenew = (Remove-StringSpecialCharacter -string $Titlenew -keep "-"," ","(",")",".","_") + $ext
    $Titlenew = $Titlenew.replace(' ',"%20")
    
    return "F`t$Titlenew`t$Total`t$datehex`n"
}

$previousFolder = ""
function Directories($presentation){
    #$newfolder = ""
    #$curretd = ""
    
    if($global:previousFolder -ne $presentation.Folder){
        $filldirs = inbetweendirs -cdir $global:previousFolder -ndir $presentation.Folder 
        $global:previousFolder = $presentation.Folder
        $dirtxt = ""
        
        foreach($d in $filldirs){
            $dirtxt += ("`nD $($d.Replace(' ','%20'))     4096    0x5a21d1e7`n")
        #    $currentd = $d
        }
        if($revisionReport){
            return ($dirtxt + (PresentationLineRevisions -presentation $presentation -folder $global:previousFolder))
        }
        else{
            return ($dirtxt + (PresentationLine($presentation)))
        }
    }
    if($revisionReport){
        return ("" + (PresentationLineRevisions -presentation $presentation -folder $global:previousFolder))
    }
    else{
        return ("" + (PresentationLine($presentation)))   
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
$sorted = $xmlpsych.MediasiteReport.Presentations.Presentation | Sort-Object -Property Folder

write-host "Converting to QDirStat format"
$tout = OutputFile($sorted)
write-host "Saving to: $output"
$tout | Out-File -FilePath $output -Encoding Ascii