# aka workaround for Corsair Composite Virtual Input Device
 Script to reinit/reinstall driver for Corsair Composite Virtual Input Device for those who experience disappearing of that device on ICUE start.

"Admin rights" are required. To launch from link with admin rights add "powershell.exe " (without quotation marks) to the beginning of Target field in link Properties, then click Advanced and check "Run as Administrator". To keep window from closing add "-NoExit" after powershell.exe so final path should looks like that *powershell.exe -NoExit "C:\Something Something\Folder\reinstall_driver.ps1"*

Add *-force* in the end to reinstall driver anyway.
