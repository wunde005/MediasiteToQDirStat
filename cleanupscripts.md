# Clean up scripts 

In QDirStat go to Settings-Configure QDirStat

In the "Cleanup Actions" tab

click +

Fill in Title: "Presentation Archive" for example

Fill in Command Line: <path to script>/QueueP.sh archive %p

 * The name archive will be used to create the id file with the list of presentations

Set refresh policy to "Assume Item has been deleted" or "No Refresh" depending on if you want it to disapear from the current view

select "Directories" and "Files" works for section

click apply

# The config is stored in ~/.config/QDirStat/QDirStat-cleanup.conf.  I've included for example.