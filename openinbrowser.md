# open in browser variable not set

The script needs a system variable set to tell it what the url is for the mediasite server

 * open bash
 * edit ~/.bash_profile

 * add line:

`export mediasiteserver="https://<servername>/mediasite"`

The script will append `/Manage/#module=Sf.Manage.PresentationSummary&args[id]=$id`

 * restart bash


------------------------
# other variables that need to be set:

wsl: (optional, it will use the 'sensible-browser' command if not set)

~/.bash_aliases
`alias chrome="/mnt/c/Program\ Files\ \(x86\)/Google/Chrome/Application/chrome.exe"`

