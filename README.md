# MediasiteToQDirStat
Converts Mediasite Storage report to QDirStat cache file
   PowerShell script to convert Mediasite Storage report XML file to QDirStat cache format.

       .\convert.ps1 -report "Mediasite Storage report.xml" -output "qdirstat.out"
    Reading Mediasite report: Mediasite Storage report.xml
    Converting to QDirStat format
    Saving to: qdirstat.out

    QDirStat info can be found here: https://github.com/shundhammer/qdirstat

    It is recommened to add mime setting for .head,.version and .archive
    along with settings for the views extensions .0,.1,.10,.100....
    This will allow you to set the colors for the graph
    A example QDirStat-mime.conf has been included and can by used inplace of the default one

Example Storage report viewed in QDirStat:
![Example QDirStat](/images/Example.jpg)
