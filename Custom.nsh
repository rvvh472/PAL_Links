${SegmentFile}
!define StrRep "!insertmacro StrRep"
!macro StrRep output string old new
	Push `${string}`
	Push `${old}`
	Push `${new}`
	!ifdef __UNINSTALL__
		Call un.StrRep
	!else
		Call StrRep
	!endif
	Pop ${output}
!macroend
!macro Func_StrRep un
	Function ${un}StrRep
		Exch $R2 ;new
		Exch 1
		Exch $R1 ;old
		Exch 2
		Exch $R0 ;string
		Push $R3
		Push $R4
		Push $R5
		Push $R6
		Push $R7
		Push $R8
		Push $R9
 
		StrCpy $R3 0
		StrLen $R4 $R1
		StrLen $R6 $R0
		StrLen $R9 $R2
		loop:
			StrCpy $R5 $R0 $R4 $R3
			StrCmp $R5 $R1 found
			StrCmp $R3 $R6 done
			IntOp $R3 $R3 + 1 ;move offset by 1 to check the next character
			Goto loop
		found:
			StrCpy $R5 $R0 $R3
			IntOp $R8 $R3 + $R4
			StrCpy $R7 $R0 "" $R8
			StrCpy $R0 $R5$R2$R7
			StrLen $R6 $R0
			IntOp $R3 $R3 + $R9 ;move offset by length of the replacement string
			Goto loop
		done:
 
		Pop $R9
		Pop $R8
		Pop $R7
		Pop $R6
		Pop $R5
		Pop $R4
		Pop $R3
		Push $R0
		Push $R1
		Pop $R0
		Pop $R1
		Pop $R0
		Pop $R2
		Exch $R1
	FunctionEnd
!macroend
!insertmacro Func_StrRep ""
!insertmacro Func_StrRep "un."
Var /GLOBAL redirectType

Function HandleRedirection
	Var /GLOBAL path
	Var /GLOBAL pathparent
	Var /GLOBAL count
	Var /GLOBAL target
	Var /GLOBAL inipath
	Var /GLOBAL sysdrive

	StrCpy $inipath "$EXEPATH"
	${WordFind} "$inipath" "\" "-1" $inipath
	StrCpy $inipath "$inipath" -4
	StrCpy $inipath "$EXEDIR\App\Appinfo\Launcher\$inipath.ini"
	IntOp $count 1 + 0

	link:
		ReadINIStr $path $inipath "$redirectTypeRedirect$count" Path
		${If} $path == ""
			Goto postlink
		${EndIf}

		ReadINIStr $target "$inipath" "$redirectTypeRedirect$count" Target
		${If} $target == ""
			MessageBox mb_ok "The target specified in $redirectTypeRedirect$count is empty."
		${Else}
			StrCpy $target "$EXEDIR\Data\$target"
		${EndIf}

		ProcessPathAndTarget

		IntOp $count $count + 1
		Goto link

	postlink:
FunctionEnd

Function ProcessPathAndTarget
	${StrRep} $path $path "%PAL:AppDir%" "$EXEDIR\App"
	${StrRep} $path $path "%PAL:DataDir%" "$EXEDIR\Data"
	${StrRep} $path $path "%UserProfile%" "$PROFILE"
	SetShellVarContext all
	${StrRep} $path $path "%AllUsersProfile%" "$APPDATA"
	${StrRep} $path $path "%ProgramData%" "$APPDATA"
	SetShellVarContext current
	${StrRep} $path $path "%LocalAppData%" "$LOCALAPPDATA"
	${StrRep} $path $path "%AppData%" "$APPDATA"
	${StrRep} $path $path "%Documents%" "$DOCUMENTS"
	StrCpy $sysdrive "$WINDIR" 2
	${StrRep} $path $path "%SystemDrive%" "$sysdrive"
	${StrRep} $path $path "%AppDataLocalLow%" "$PROFILE\AppData\LocalLow"

	ProcessRedirection
FunctionEnd

Function ProcessRedirection
	${WordFind} "$path" "\" "-2{*" $pathparent
	CreateDirectory "$pathparent"
	Rename "$path\" "$path PAF Backup\"

	${Switch} "$redirectType"
	${Case} "Symlink"
		System::Call "kernel32::CreateSymbolicLinkW(w `$path`, w `$target`, i 1) i .s"
	${Case} "Hardlink"
		System::Call "kernel32::CreateHardLinkW(w `$path`, w `$target`, i 1) i .s"
	${Case} "Junction"
		ExecWait 'mklink /J "$path" "$target"'
	${EndSwitch}

	CreateDirectory "$target"
	Pop $1

	${If} $1 <> 1
		MessageBox mb_ok "This portable application has failed to launch. Please make sure you are running it off an NTFS-formatted drive."
		Goto abort
	${EndIf}
	
FunctionEnd

!macro CleanUp
	${StrRep} $path $path "%PAL:AppDir%" "$EXEDIR\App"
	${StrRep} $path $path "%PAL:DataDir%" "$EXEDIR\Data"
	${StrRep} $path $path "%UserProfile%" "$PROFILE"
	SetShellVarContext all
	${StrRep} $path $path "%AllUsersProfile%" "$APPDATA"
	${StrRep} $path $path "%ProgramData%" "$APPDATA"
	SetShellVarContext current
	${StrRep} $path $path "%LocalAppData%" "$LOCALAPPDATA"
	${StrRep} $path $path "%AppData%" "$APPDATA"
	${StrRep} $path $path "%Documents%" "$DOCUMENTS"
	StrCpy $sysdrive "$WINDIR" 2
	${StrRep} $path $path "%SystemDrive%" "$sysdrive"
	${StrRep} $path $path "%AppDataLocalLow%" "$PROFILE\AppData\LocalLow"

	${WordFind} "$path" "\" "-2{*" $pathparent
	System::Call "kernel32::RemoveDirectoryW(w `$path`) i.s"

	removeparent:
		System::Call "kernel32::RemoveDirectoryW(w `$pathparent`) i.s"
		${WordFind} "$pathparent" "\" "-2{*" $pathparent
		${WordFind} "$pathparent" "\" "+1" $root
		${If} $pathparent == $root
			Goto postremoveparent
		${Else}
			Goto removeparent
		${EndIf}

	postremoveparent:
		Rename "$path PAF Backup\" "$path\"
		StrCpy $path ""
!macroend

Function CleanUpOnFail
	abort:
		${If} $count == 0
			Quit
		${EndIf}
		ReadINIStr $path $inipath "$redirectTypeRedirect$count" Path
		Goto CleanUp
		IntOp $count $count - 1
		Goto abort
FunctionEnd

Function CleanupOnExit
	IntOp $count 0 + 1
	delink:
		StrCpy $path ""
		ReadINIStr $path $inipath "$redirectTypeRedirect$count" Path
		${If} $path == ""
			Goto done
		${EndIf}
		Goto CleanUp
		IntOp $count $count + 1
		Goto delink
	done:
FunctionEnd

Function SystemMetrics

    System::Call user32::GetSystemMetrics(i0)i.r0
    System::Call user32::GetSystemMetrics(i1)i.r1

	Var /GLOBAL ratiowh
	Var /GLOBAL ratiowhhex
	Var /GLOBAL wtimesten
	Var /GLOBAL sw43dword
	IntOp $3 $1 / 3
	IntOp $4 $3 * 4
	IntOp $wtimesten $0 * 100
	IntOp $ratiowh $wtimesten / $1
	IntFmt $ratiowhhex "%08x" $ratiowh

	IntFmt $5 "%08x" $0
	StrCpy $6 $5 "" -2
	StrCpy $7 ","
	StrCpy $8 $5 "2" -4
	StrCpy $9 "$6$7$8"

	IntFmt $R5 "%08x" $1
	StrCpy $R6 $R5 "" -2
	StrCpy $R7 ","
	StrCpy $R8 $R5 "2" -4
	StrCpy $R9 "$R6$R7$R8"

	IntFmt $sw43dword "%08x" $4
		
		${SetEnvironmentVariable} ScreenWidth $0
		${SetEnvironmentVariable} ScreenHeight  $1
		${SetEnvironmentVariable} AspectRatio $ratiowh
		${SetEnvironmentVariable} AspectRatioDWORD $ratiowhhex
		${SetEnvironmentVariable} ScreenWidth43  $4
		${SetEnvironmentVariable} ScreenWidth43DWORD  $sw43dword
		${SetEnvironmentVariable} ScreenWidthHEX  $9
		${SetEnvironmentVariable} ScreenHeightHEX  $R9
		${SetEnvironmentVariable} ScreenWidthDWORD $5
		${SetEnvironmentVariable} ScreenHeightDWORD $R5
FunctionEnd

${SegmentInit}
	Call SystemMetrics
!macroend

${SegmentPreExec}
	StrCpy $redirectType "Symlink"
    Call HandleRedirection

    StrCpy $redirectType "Hardlink"
    Call HandleRedirection

    StrCpy $redirectType "Junction"
    Call HandleRedirection
!macroend	

${SegmentPost}
    Call CleanupOnExit
!macroend

${SegmentUnload}
	${GetTime} "" "L" $0 $1 $2 $3 $4 $5 $6
	Rename "$EXEDIR\Data\Screenshots\TEMP\" "$EXEDIR\Data\Screenshots\$0.$1.$2 $4.$5.$6\"
!macroend

