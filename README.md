# PAL_Links
PAL_Links is a small script I wrote that adds Symbolic Link, Hard Link and Directory Junction capabilities to the PortableApps.com-format applications.
# Why symlinks, hardlinks and junctions instead of PortableApps'DirectoriesMove?
## Pros
When the Data directory of a portable app gets big (or if the computer it's being run on has a slow HDD), there is a risk of data loss.

If the hidden move operation is somehow aborted, the data will be affected. Normally, this isn't a problem as it takes miliseconds with small programs but with software that stores a lot of data on the system (think videogame savegames or shader caches), the risk is significant.

I actually experienced this several times. Besides data-safety, using my script instead of PA's DirectoriesMove greatly improves app startup and post-launch cleanup speed as there's no moving around of large ammounts of data.
Hardlinks and junctions do not require administrator privileges.
## Cons
Applications using this script can only be run from NTFS-formatted drive so putting them on FAT32 flash drives (the main use case for PApps) is not possible as that filesystem doesn't support symbolic links, hardlinks and junctions.

⚠️Administrator privileges are also required for the creation of symbolic links so be sure to enable the RunAsAdmin=compile-force flag in your appname.ini PRIOR to recompiling. This will trigger UAC every time the app is run which can be annoying. I personally always disable UAC so that's not a problem for me but it might be for you. This also means that you can't run the application in an environment where you don't have administrator privileges.
# Usage
1. Download Custom.nsh from this repo and put it in your Appinfo>Launcher directory, next to the appname.ini file.
2. Be sure to enable administrator privileges flag in your launcher.ini if You are using symlink. For Hardlink and Junction, This is not necessary. This can be done by adding the following line in the [Launch] section of the file.
 ```
 RunAsAdmin=compile-force
 ```
3. Recompile the portable application using the Portableapps Launcher Generator. This can be done by downloading [this](https://portableapps.com/apps/development/portableapps.com_launcher), installing it somewhere and drag-and-dropping the directory containing the application (the one that contains the App and Data dirs) that you want to make portable to PortableApps.comLauncherGenerator.exe
 
4. In your appname.ini file, create the following section for each symbolic link that you want to make:

```
[SymlinkRedirectN]
Path=  
Target= 
```

 ⚠️Replace the N in SymlinkRedirectN, HardlinkRedirectN and JunctionRedirectN with the number of the Symlink, Hardlink, Junction respectively, like you were using FileWriteN.
See the example below.
  
  
For Path, use the path where the symbolic link wil be located. This is the path of the directory that you want to make portable, the path that you would put on the **RIGHT** side of the "**=**" if you were using DirectoriesMove. Most wilidcards from PA are supported (more below). The DirectoriesCleanupIfEmpty section is also replicated by my script and should be left empty (if you aren't using DirectoriesMove as well). The parent directories of the SymLink will be recursively removed if they are empty. If there is already a directory at this path, it will be renamed when the app is run and renamed back when it is closed.

For Target, use the name of the directory in your PAL:DataDir (the Data directory that is created after the app is run) that the symbolic link will point to. This is the path that you would put on the **LEFT** if you were using DirectoriesMove. If this directory doesn't already exist (like if you put it in DefaultData), it will be automatically created.
 
 5. Run the app and see if it works. Be aware that it will not run from a non-NTFS formatted drive as other filesystems like FAT32 don't support Symbolic Links.
  
 # Wildcards
  
This script supports the following wildcards that PortableApps uses:
```
  %PAL:AppDir%
  %PAL:DataDir
  %UserProfile%
  %AllUsersProfile%
  %LocalAppData%
  %AppData%
  %Documents%
  %SystemDrive%
```
  
 Use them like you would if you were using DirectoriesMove. Documentation [here](https://portableapps.com/manuals/PortableApps.comLauncher/ref/envsub.html).
  
 This script contains two more variables that would be useful:
```
  %AppDataLocalLow% - translates to %UserProfile%\AppData\LocalLow
  %ProgramData% - translates to %SystemDrive%\ProgramData (same as %AllUsersProfile%).
```
## Example launcher.ini:
```
[Launch]
Name=AppName
ProgramExecutable=AppDir\appname.exe
DirectoryMoveOK=yes
WorkingDirectory=%PAL:AppDir%\AppDir
runasadmin=compile-force        ⚠️

[SymlinkRedirect1]
Path=%PAL:AppDir%\Config
Target=Configs
  
[SymlinkRedirect2]
Path=%AppData%\AppName
Target=User Data

[HardlinkRedirect1]
Path=%PAL:AppDir%\appname.confiz
Target=appname.config
  
[HardlinkRedirect2]
Path=%AppData%\appname.config
Target=appname.config

[JunctionRedirect1]
Path=%PAL:AppDir%\Config
Target=Configs
  
[JunctionRedirect2]
Path=%AppData%\AppName
Target=User Data

```
 # Resolution Wildcards
[lorenzo-zurini](https://github.com/lorenzo-zurini) have made a lot of portable videogames using PortableApps launchers and a lot of them need to have the display resolution written somewhere in their config files or in the registry. However, PA does not provide a way of obtaining these values so he added it to his script. It automatically obtains the dimensions of the main display and processes them in several ways resulting in the following environment variables:
 ```
 The values below are for a resolution of 1920x1080:
 %ScreenWidth% - the width of the screen (1920)
 %ScreenWidthHEX% - the width of the screen in hex (80,07)
 %ScreenWidthDWORD% - the width of the screen formatted to %08x (00000780)
 %ScreenHeight% - the height of the screen (1080)
 %ScreenHeightHEX% - the height of the screen in hex (38,04)
 %ScreenHeightDWORD% - the height of the screen formatted to %08x (00000438)
 %AspectRatio% - the aspect ratio of the screen x 1000 (177)
 %AspectRatioDWORD% - the aspect ratio in a %08x format (000000b1)
 %ScreenWidth43% -  the width of the screen if the aspect ratio were 4:3 (1440)
 %ScreenWidth43DWORD% - the same but formatted to %08x (000005a0)
 ```
 Use them with [FileWriteN] to edit the resolutions in the configs programatically. The hex ones are usually used in the registry by old games/apps.

# Credit
I appreciate [lorenzo-zurini](https://github.com/lorenzo-zurini) for his work for symlink. I take some code and inspiration from [his script](https://github.com/lorenzo-zurini/PALSymLink) to create a new one with proper and efficient structure that include Hardlink and junctions as well for devices without Admin Permissions.
  # License
Feel free to use this in your portable apps however you like.  
I would appreciate a credit if you feel so inclined.
