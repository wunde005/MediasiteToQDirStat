#~/bin/bash
shopt -s expand_aliases
source ~/.bash_aliases
args=("$@")

id=`grep -F ",${args[0]}," $PWD/idmap.txt | cut -f 1 -d ,`

if alias chrome 2>/dev/null; then 
   echo "chrome alias defined"
else 
   alias chrome=sensible-browser
fi

if [ -z "$mediasite2server" ]
then
    echo "missing mediasite server info"
    chrome "https://github.com/wunde005/MediasiteToQDirStat/blob/master/openinbrowser.md#open-in-browser-variable-not-set"
    exit -1 

elif [ -z "$id" ]
then
    echo "Presentation id not found."
#    exit 1
else
    echo "Starting Browser"
   chrome "https://mediasite.csom.umn.edu/mediasite/Manage/#module=Sf.Manage.PresentationSummary&args[id]=$id"
    #chrome "$mediasiteserver/Manage/#module=Sf.Manage.PresentationSummary&args[id]=$id"
fi
