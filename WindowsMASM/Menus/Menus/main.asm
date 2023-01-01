.386
.model flat, stdcall
option casemap:none

include S:\masm32\include\windows.inc

includelib S:\masm32\lib\user32.lib
include S:\masm32\include\user32.inc

includelib S:\masm32\lib\kernel32.lib
include S:\masm32\include\kernel32.inc

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

.data
ClassName db "SimpleWinClass",0
AppName  word 'o','u','r',' ', 'w','i','n','d','o','w',0
MenuName word 'F','i','r','s','t','M','e','n','u',0                ; The name of our menu in the resource file.
test_string word 't','e','s','t',0
hello_string word 'h','e','l','l','o',0
goodbye_string word 'b','y','e',0

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?

.const
IDM_TEST equ 1                    ; Menu IDs
IDM_HELLO equ 2
IDM_GOODBYE equ 3
IDM_EXIT equ 4

.code
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
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
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg == WM_DESTROY
        invoke PostQuitMessage, NULL
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        .if ax == IDM_TEST
            invoke MessageBoxW, hWnd, offset test_string, offset AppName, NULL
        .elseif ax == IDM_HELLO
            invoke MessageBoxW, hWnd, offset hello_string, offset AppName, NULL
        .elseif ax == IDM_GOODBYE
            invoke MessageBoxW, hWnd, offset goodbye_string, offset AppName, NULL
        .elseif ax == IDM_EXIT
            invoke ExitProcess, 0
        .endif
    .ELSE
        invoke DefWindowProcW, hWnd, uMsg, wParam, lParam
    .ENDIF
    ret
WndProc endp

main:
    invoke GetModuleHandle, NULL
    mov    hInstance,eax
    invoke GetCommandLine
    mov CommandLine,eax
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax
end main