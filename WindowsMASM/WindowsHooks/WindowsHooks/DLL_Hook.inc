; IN THE DLL INCLUDE FILE ALL WE HAVE TO DO
; PROTOTYPE THE FUNCTIONS 
; include this file to interact with the .dll library ! !
InstallHook proto :DWORD
UninstallHook proto
MouseProc proto :DWORD,:DWORD,:DWORD