;	This program demontrats what exactly a Process is and does ....
;	we will create a new process when the user selects the "create process" menu item. 
;	we'll attempt to execute "msgbox.exe".
;
;	If the user wants to terminate the new process, they can select the "terminate process" menu item.
;	The program will check first if the new process is already destroyed,
;	if it is not, the program  will call TerminateProcess function to destroy the new process.
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
; lets initialize the data for our menu !
    IDM_CREATE_PROCESS equ 1 ; menu selection to "create a process"     \
    IDM_TERMINATE equ 2      ; menu selection to "terminate a process"===| all of these menu id numbers are coming from our resource.h header file which has those values preset ! ! !
    IDM_EXIT equ 3           ; menu selection to "exit the program"     /
  
.data
; lets initialize the data for our Wide Window, menu and to handle the processes
; again we are going to be working with wide string so lets make use of our macro !
    WIDE ClassName, "Win32ASMProcessClass",0
    WIDE AppName, "Win32 ASM Process Example",0
    WIDE MenuName ,"MyMenu",0
    processInfo PROCESS_INFORMATION <>
    WIDE programname, "MoreStrings.exe",0 ; the name of the .exe file we want to execute ! (please note that the .exe file must be in the same folder location as this program ! !)

.data?
    hInstance HINSTANCE ?
    CommandLine LPSTR ?
    hMenu HANDLE ?
    ExitCode DWORD ? ; contains the process exitcode status from GetExitCodeProcess call.

.code
; lets start by setting up our window that is going to render our application --- call the win32 api ! ! 
wWinMain proc hInst:HINSTANCE, hPrevInstance:HINSTANCE, pCmdLine:LPSTR, nCmdShow:DWORD
    ; lets set up the variables we need for our window !
    LOCAL wc:WNDCLASSEXW
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    mov   wc.cbSize,SIZEOF WNDCLASSEXW
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL

    push  hInst
    pop   wc.hInstance

    mov   wc.hbrBackground,COLOR_WINDOW+2 ; set the background color of our window !
    mov   wc.lpszMenuName, offset MenuName
    mov   wc.lpszClassName,OFFSET ClassName

    invoke LoadIconW,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax

    invoke LoadCursorW,NULL,IDC_ARROW
    mov   wc.hCursor,eax

    invoke RegisterClassExW, addr wc
    invoke CreateWindowExW,NULL,ADDR ClassName,ADDR AppName,
            WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,
            CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,NULL,NULL,
            hInst,NULL
    mov   hwnd,eax
    invoke ShowWindow, hwnd,SW_SHOWNORMAL
    invoke UpdateWindow, hwnd

    ; the following is new code additions !
    .WHILE TRUE
        invoke GetMessageW, ADDR msg,NULL,0,0
        .BREAK .IF (!eax)
        invoke DispatchMessageW, ADDR msg
    .ENDW

    mov     eax,msg.wParam
    ret
wWinMain endp

; Now lets handle all of the windows messages that we are intrested in using for our program ! !
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL startInfo:STARTUPINFO ; we'll need this for our call to CreateProcess() ! !
    .IF uMsg == WM_DESTROY
        invoke PostQuitMessage, NULL
    .ELSEIF uMsg==WM_INITMENUPOPUP
        invoke GetExitCodeProcess,processInfo.hProcess,ADDR ExitCode
        .if eax==TRUE
            .if ExitCode==STILL_ACTIVE
                invoke EnableMenuItem,hMenu,IDM_CREATE_PROCESS,MF_GRAYED
                invoke EnableMenuItem,hMenu,IDM_TERMINATE,MF_ENABLED
            .else
                invoke EnableMenuItem,hMenu,IDM_CREATE_PROCESS,MF_ENABLED
                invoke EnableMenuItem,hMenu,IDM_TERMINATE,MF_GRAYED
            .endif
        .else
            invoke EnableMenuItem,hMenu,IDM_CREATE_PROCESS,MF_ENABLED
            invoke EnableMenuItem,hMenu,IDM_TERMINATE,MF_GRAYED
        .endif
    .ELSEIF uMsg==WM_COMMAND
        mov eax,wParam
        .if lParam==0
            .if ax==IDM_CREATE_PROCESS
                .if processInfo.hProcess!=0
                    invoke CloseHandle,processInfo.hProcess
                    mov processInfo.hProcess,0
                .endif

                invoke GetStartupInfoW,ADDR startInfo
                invoke CreateProcessW,ADDR programname,NULL,NULL,NULL,FALSE,
                                        NORMAL_PRIORITY_CLASS,
                                        NULL,NULL,ADDR startInfo,ADDR processInfo
                invoke CloseHandle,processInfo.hThread
            .elseif ax==IDM_TERMINATE
                invoke GetExitCodeProcess,processInfo.hProcess,ADDR ExitCode
                .if ExitCode==STILL_ACTIVE
                    invoke TerminateProcess,processInfo.hProcess,0
                .endif
                invoke CloseHandle,processInfo.hProcess
                mov processInfo.hProcess,0
            .else
                invoke DestroyWindow,hWnd
            .endif
        .endif
    .ELSE
        invoke DefWindowProcW, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    ret
WndProc endp

; All the pre-reqs done so lets display it on the screen
main:
    invoke GetModuleHandle, NULL
    mov    hInstance,eax
    invoke GetCommandLine
    mov CommandLine,eax
    invoke wWinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax
end main
