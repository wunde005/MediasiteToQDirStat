#~/bin/bash
shopt -s expand_aliases
source ~/.bash_aliases
args=("$@")

id=`grep -F ",${args[0]}," $PWD/idmap.txt | cut -f 1 -d ,`

if [ -z "$media2siteserver" ]
then
    echo "missing mediasite server info"
    chrome "https://github.com/wunde005/MediasiteToQDirStat/blob/master/openinbrowser.md"

    exit 255 

elif [ -z "$id" ]
then
    echo "Presentation id not found."
#    exit 1
else
    echo "Starting Browser"
   chrome "https://mediasite.csom.umn.edu/mediasite/Manage/#module=Sf.Manage.PresentationSummary&args[id]=$id"
    #chrome "$mediasiteserver/Manage/#module=Sf.Manage.PresentationSummary&args[id]=$id"
fi
