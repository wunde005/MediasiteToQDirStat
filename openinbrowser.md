# open in browser variable not set

The scrip needs a system variable set to tell it what the url is for the mediasite server

 * open bash
 * edit ~/.bash_profile

 * add line:

`export mediasiteserver="<server url>"`

The script will append `/Manage/#module=Sf.Manage.PresentationSummary&args[id]=$id`

 * restart bash
