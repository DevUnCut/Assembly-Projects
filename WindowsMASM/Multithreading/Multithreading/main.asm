; Let try a multithreaded aproach for an
; a program that adds the eax register to itself
; 600,000,000 times and notice just how much more beneficial it is!
.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib

WIDE MACRO varname:REQ, string:REQ, args:VARARG
    @CatStr(<&varname& WORD >, !', @SubStr(<&string&>, 2, 1), !')

    % FORC chr, <@SubStr(<&string&>, 3, @SizeStr(<&string&>)-3)>
        WORD '&chr&'
    ENDM

    FOR arg, <&args&>
        WORD &arg&
    ENDM

ENDM

.const
	IDM_CREATE_THREAD equ 1
	IDM_EXIT		  equ 2
	WM_FINISH		  equ WM_USER+100h

.data

	WIDE ClassName, "Win32ASMThreadClass",0
	WIDE AppName, "Win32 ASM MultiThreading Example",0
	WIDE MenuName, "MyMenu",0
	WIDE SuccessString, "The calculation is completed", 0
	WIDE UnsuccessfulString, "The calculation failed (-_-)", 0
.data?
	hInstance HINSTANCE ?
	CommandLine LPSTR ?
	hwnd HANDLE ?
	ThreadID DWORD ?

.code

wWinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
    LOCAL wc:WNDCLASSEXW ; create local variables onto the stack !
    LOCAL msg:MSG

    mov wc.cbSize, sizeof WNDCLASSEXW
    mov wc.lpfnWndProc, offset WndProc
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL

    push hInst
    pop wc.hInstance

    mov   wc.hbrBackground,COLOR_WINDOW+9
    mov   wc.lpszMenuName, offset MenuName
    mov   wc.lpszClassName,OFFSET ClassName

    invoke LoadIcon,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax

    invoke LoadCursor,NULL,IDC_ARROW
    mov   wc.hCursor,eax

    invoke RegisterClassExW, addr wc ; register our window class

    invoke CreateWindowExW, WS_EX_CLIENTEDGE,
            offset ClassName,
            offset AppName,
            WS_OVERLAPPEDWINDOW, ; The style of the window being created <read Windows 32 api for more details>
            CW_USEDEFAULT, ; x-coord
            CW_USEDEFAULT, ; y-coord
            300, ; width value
            200, ; height value
            hwnd,
            NULL, hInst, NULL

    mov   hwnd,eax

    ; display our window on desktop
    invoke ShowWindow, hwnd,CmdShow

    ; refresh the client area
    invoke UpdateWindow, hwnd

    ; Enter infinite message loop
    .WHILE TRUE
                invoke GetMessageW, addr msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
   .ENDW
   ; return the exit code and store it in the eax register !
    mov     eax,msg.wParam
    ret
wWinMain endp

ThreadProc PROC USES ecx Param:DWORD
	mov  ecx,600000000
	Loop1:
		add  eax,eax
		dec  ecx
		jz   Get_out
		jmp  Loop1
	Get_out:
		invoke PostMessage,hwnd,WM_FINISH,NULL,NULL
		ret
ThreadProc ENDP

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL
    .ELSEIF uMsg==WM_COMMAND
        mov eax,wParam
        .if lParam==0
            .if ax==IDM_CREATE_THREAD
                mov  eax,OFFSET ThreadProc
                invoke CreateThread,NULL,NULL,eax,NULL, 0, ADDR ThreadID
                invoke CloseHandle,eax
            .else
                invoke DestroyWindow,hWnd
            .endif
        .endif
    .ELSEIF uMsg == WM_FINISH
        invoke MessageBoxW,NULL,ADDR SuccessString,ADDR AppName,MB_OK
    .ELSE
        invoke DefWindowProcW,hWnd,uMsg,wParam,lParam
        ret
    .ENDIF
    xor    eax,eax
    ret
WndProc endp

main:
    invoke GetModuleHandle, NULL
    mov    hInstance,eax
    invoke GetCommandLine
    mov CommandLine,eax
    invoke wWinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax
end main

