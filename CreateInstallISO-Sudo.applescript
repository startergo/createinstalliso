#!/usr/bin/osascript
on run
    set scriptPath to POSIX path of (path to me)
    set scriptDir to do shell script "dirname " & quoted form of scriptPath
    set executablePath to scriptDir & "/createinstalliso-interactive"
    
    tell application "Terminal"
        activate
        do script "cd " & quoted form of scriptDir & " && sudo " & quoted form of executablePath & "; echo ''; echo 'Press any key to close this window...'; read -n 1; exit"
    end tell
end run
