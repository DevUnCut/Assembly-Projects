; This is the equivalant to a header's implementation file
; which would be the .h's .cpp file, in this case it is a .asm file !
; 
; just like in c++ we're going to start it off as a regular c++ program
; or rather in this case a Microsoft Windows Masm32 bit program !
.386
.model flat, stdcall
option casemap:none

; and again it's just like a regular masm32 bit program so include any libraries
; that our MyCustomFunction might need in order to complete its task at hand !
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib

; this is were it differs since it is not going to be a part of our main program
; WE DO NOT NEED A main or start label section just the code section for our
; function implementation ! !
.data
	AppName db "DLL Skeleton",0
	HelloMsg db "Hello, you're calling a function in this DLL",0
	LoadMsg db "The DLL is loaded",0
	UnloadMsg db "The DLL is unloaded",0
	ThreadCreated db "A thread is created in this process",0
	ThreadDestroyed db "A thread is destroyed in this process",0
.code
; NOW LET US DEFINE OUR ENTRY POINT TO OUR DLL ! ! ! !
; We can name the entrypoint function anything we wish so long as you have a matching END <Entrypoint function name>.
; This Entry Point function takes in three parameters, only the first two of which are important.
; hInstDLL is the module handle of the DLL. It is not the same as the instance handle of the process.
; KEEP THIS VALUE IF WE NEED TO USE IT OTHERWISE WE NEED TO FIND A WAY OF GETTING IT AGAIN IF WE DECIDED NOT TO KEEP IT !
;
; You can't obtain it again easily via our reason variable
; reason can be one of the four values:
; - DLL_PROCESS_ATTACH: The DLL receives this value when it is first injected into the process address space. You can use this opportunity to do initialization.
; - DLL_PROCESS_DETACH: The DLL receives this value when it is being unloaded from the process address space. You can use this opportunity to do some cleanup such as deallocate memory and so on.
; - DLL_THREAD_ATTACH: The DLL receives this value when the process creates a new thread.
; - DLL_THREAD_DETACH: The DLL receives this value when a thread in the process is destroyed.

DllEntry proc hInstDLL:HINSTANCE, reason:DWORD, reserved1:LPVOID
; WE MUST RETURN, TRUE in eax if you want the DLL TO KEEP ON RUNNING. If WE return FALSE, the DLL will not be loaded.
;
; For example, if your initialization code must allocate some memory and it cannot do that successfully,
; then the entrypoint function should return FALSE to indicate that the DLL cannot run.
	.if reason==DLL_PROCESS_ATTACH
		invoke MessageBoxA,NULL,addr LoadMsg,addr AppName,MB_OK
	.elseif reason==DLL_PROCESS_DETACH
		invoke MessageBoxA,NULL,addr UnloadMsg,addr AppName,MB_OK
	.elseif reason==DLL_THREAD_ATTACH
		invoke MessageBoxA,NULL,addr ThreadCreated,addr AppName,MB_OK
	.else        ; DLL_THREAD_DETACH
		invoke MessageBoxA,NULL,addr ThreadDestroyed,addr AppName,MB_OK
	.endif

	mov  eax,TRUE
	ret
DllEntry endp

; the following is a dummy function and does nothing it is just a
; show where our custom dll function get implemented and typed up at
MyCustomFunction proc
	invoke MessageBoxA, NULL, addr HelloMsg, addr AppName, MB_OK
	ret
MyCustomFunction endp
END DllEntry