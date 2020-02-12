# MediasiteToQDirStat

PowerShell script to convert Mediasite Storage report XML file to QDirStat cache format.

    Example:
    >.\convert.ps1 -report "Mediasite Storage report.xml" -output "qdirstat.out"
    Reading Mediasite report: Mediasite Storage report.xml
    Converting to QDirStat format
    Saving to: qdirstat.out

    Then in WSL or linux you can run qdirstat
    >qdirstat -c qdirstat.out
    
Notes:

    QDirStat info can be found here: https://github.com/shundhammer/qdirstat

    It is recommened to add mime setting for .head,.version and .archive
    along with settings for the views extensions .0,.1,.10,.100....
    This will allow you to set the colors for the graph
    A sample QDirStat-mime.conf has been included or it can by used inplace of the default one

Example Storage report viewed in QDirStat:
![Example QDirStat](/images/Example.jpg)

Alternate Reports:

* revisionReport
  - Outputs presentation as folder with files representing head,revision and archive using extensions
* storagePerView
  - Outputs file size as Size/View 
* LastViewedReport 
  - Outputs file size as seconds since last viewed 
* views
  - Outputs file size as views  
  
Example Storage revision report viewed in QDirStat:
![Example QDirStat Revision Report](/images/Example-revisionReport.jpg)


[Notes on getting open in browser working](openinbrowser.md)
