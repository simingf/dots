#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

;CLOSE WINDOWS

!Esc::
WinClose A
return

;MULTI INSTANCE APPS

;GIT BASH

!Enter::
IfWinExist ahk_exe mintty.exe
{
	WinGet, WinList, List, ahk_exe mintty.exe
	Loop, % WinList
		winactivate, % "ahk_id " WinList%A_Index%
}
else
{
	run, "C:\Program Files\Git\git-bash.exe"
}
return

!+Enter::
run, "C:\Program Files\Git\git-bash.exe"
return

;VS CODE

!k::
IfWinExist ahk_exe Code.exe
{
	WinGet, WinList, List, ahk_exe Code.exe
	Loop, % WinList
		winactivate, % "ahk_id " WinList%A_Index%
}
else
{
	run, code
}
return

!+k::
run, code
return

;FIREFOX

!f::
IfWinExist ahk_exe firefox.exe
{
	WinGet, WinList, List, ahk_exe firefox.exe
	Loop, % WinList
		winactivate, % "ahk_id " WinList%A_Index%
}
else
{
	run, firefox
}
return

!+f::
run, firefox
return

;EXPLORER

!e::
IfWinExist ahk_class CabinetWClass
{
	WinGet, WinList, List, ahk_class CabinetWClass
	Loop, % WinList
		winactivate, % "ahk_id " WinList%A_Index%
}
else
{
	run, explorer
}
return

!+e::
run, explorer
return

;NOTEPAD

!n::
IfWinExist ahk_exe Notepad.exe
{
	WinGet, WinList, List, ahk_exe Notepad.exe
	Loop, % WinList
		winactivate, % "ahk_id " WinList%A_Index%
}
else
{
	run, notepad
}
return

!+n::
run, notepad
return

;SINGLE INSTANCE APPS

!w::
IfWinExist ahk_exe WeChat.exe
	winactivate ahk_exe WeChat.exe
else
	run, "C:\Program Files (x86)\Tencent\WeChat\WeChat.exe"
return

!d::
IfWinExist ahk_exe Discord.exe
	winactivate ahk_exe Discord.exe
else
	run, "C:\Users\Sim\AppData\Local\Discord\app-1.0.9042\Discord.exe"
return

!s::
IfWinExist ahk_exe Spotify.exe
	winactivate ahk_exe Spotify.exe
else
	run, "C:\Users\Sim\AppData\Roaming\Spotify\Spotify.exe"
return