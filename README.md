KeyCast
=======

Display keystroke for desktop screencast. (demo movie: <a href="https://www.youtube.com/watch?v=RBCT56Tzpu4">youtube</a>)

Automatically Hide Password Input
---------------------------------

KeyCast detect the focused input is password input. So you do not need to disable by hand to hide input for password mostly.

Supported:

 * Native AXSecureTextField
 * Google Chrome's password input
 * Local `sudo` (hide on `sudo` is in processlist)

Download and Install
--------------------

Download .dmg from releases page:

https://github.com/cho45/KeyCast/releases

Copy KeyCast.app to your Application folder.

Scripting Bridge
----------------

KeyCast also supports scripting bridge. You can control (enable or disable) KeyCast by AppleScript or JavaScript (Yosemite).

eg.

    # enable 
    osascript -e 'tell application "KeyCast"' -e 'set enabled to true' -e 'end tell'

    # disable
    osascript -e 'tell application "KeyCast"' -e 'set enabled to false' -e 'end tell'
    
eg. (on Yosemite)

    # enable
    osascript -l JavaScript -e 'Application("KeyCast").enabled = true;' 
     
    #disable
    osascript -l JavaScript -e 'Application("KeyCast").enabled = false;' 
