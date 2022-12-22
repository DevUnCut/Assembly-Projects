.386
.model flat,stdcall
option casemap:none

include S:\masm32\include\windows.inc

include S:\masm32\include\user32.inc
includelib S:\masm32\lib\user32.lib            ; calls to functions in user32.lib and kernel32.lib

include S:\masm32\include\kernel32.inc
includelib S:\masm32\lib\kernel32.lib


WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

.DATA                     ; initialized data
ClassName db "SimpleWinClass",0        ; the name of our window class
AppName db "Our First Window",0        ; the name of our window

.DATA?                ; Uninitialized data
hInstance HINSTANCE ?        ; Instance handle of our program
CommandLine LPSTR ?
.CODE                ; Here begins our code
start:
invoke GetModuleHandle, NULL            ; get the instance handle of our program.
                                                                       ; Under Win32, hmodule==hinstance mov hInstance,eax
mov hInstance,eax
invoke GetCommandLine                        ; get the command line. You don't have to call this function IF
                                                                       ; your program doesn't process the command line.
mov CommandLine,eax
invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT        ; call the main function
invoke ExitProcess, eax                           ; quit our program. The exit code is returned in eax from WinMain.

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
    LOCAL wc:WNDCLASSEX                                            ; create local variables on stack
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    mov   wc.cbSize,SIZEOF WNDCLASSEX                   ; fill values in members of wc
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL
    push  hInstance
    pop   wc.hInstance
    mov   wc.hbrBackground,COLOR_WINDOW+1
    mov   wc.lpszMenuName,NULL
    mov   wc.lpszClassName,OFFSET ClassName
    invoke LoadIcon,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax
    invoke LoadCursor,NULL,IDC_ARROW
    mov   wc.hCursor,eax
    invoke RegisterClassEx, addr wc                       ; register our window class
    invoke CreateWindowEx,NULL,\
                ADDR ClassName,\
                ADDR AppName,\
                WS_OVERLAPPEDWINDOW,\
                CW_USEDEFAULT,\
                CW_USEDEFAULT,\
                CW_USEDEFAULT,\
                CW_USEDEFAULT,\
                NULL,\
                NULL,\
                hInst,\
                NULL
    mov   hwnd,eax
    invoke ShowWindow, hwnd,CmdShow               ; display our window on desktop
    invoke UpdateWindow, hwnd                                 ; refresh the client area

    .WHILE TRUE                                                         ; Enter message loop
                invoke GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
   .ENDW
    mov     eax,msg.wParam                                            ; return exit code in eax
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg==WM_DESTROY                           ; if the user closes our window
        invoke PostQuitMessage,NULL             ; quit our application
    .ELSE
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam     ; Default message processing
        ret
    .ENDIF
    xor eax,eax
    ret
WndProc endp

end start