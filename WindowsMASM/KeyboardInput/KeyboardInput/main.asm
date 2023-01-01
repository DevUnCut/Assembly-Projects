.386
.model flat,stdcall
option casemap:none

include S:\masm32\include\windows.inc

include S:\masm32\include\user32.inc
includelib S:\masm32\lib\user32.lib

include S:\masm32\include\kernel32.inc
includelib S:\masm32\lib\kernel32.lib

include S:\masm32\include\gdi32.inc
includelib S:\masm32\lib\gdi32.lib

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

WIDE MACRO varname:REQ, string:REQ, args:VARARG
    @CatStr(<&varname& WORD >, !', @SubStr(<&string&>, 2, 1), !')

    % FORC chr, <@SubStr(<&string&>, 3, @SizeStr(<&string&>)-3)>
        WORD '&chr&'
    ENDM

    FOR arg, <&args&>
        WORD &arg&
    ENDM

ENDM

RGB MACRO red:REQ, green:REQ, blue:REQ
    xor eax, eax

    mov ah,     blue
    shl eax,    8
    mov ah,     green
    mov al,     red
ENDM

.data
WIDE ClassName, "SimpleWinClass", 0 ; the name of our window class - let us make use of our macro
AppName word 4e93h, 6c17h, 3067h, 3059h, 0 ; The window_title ! 
char WPARAM 0                         ; the character the program receives from keyboard

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?

.code
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
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

    mov   wc.hbrBackground,COLOR_WINDOW+1
    mov   wc.lpszMenuName,NULL
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
    .WHILE TRUE
        invoke GetMessage, ADDR msg,NULL,0,0
        .BREAK .IF (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW
    mov eax,msg.wParam
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM

    LOCAL hdc:HDC
    LOCAL ps:PAINTSTRUCT

    .IF uMsg == WM_DESTROY
        invoke PostQuitMessage,NULL
    ; we can handle keyboard input multiple way depending on how we think of keyboard
    ; we can either use WM_CHAR message such thinking is to characters on the keyboard
    ; or a collection of keys with the WM_KEYDOWN and WM_KEYUP messages
    .ELSEIF uMsg == WM_CHAR
        push wParam
        pop  char
        invoke InvalidateRect, hWnd,NULL,TRUE
    ;.ELSEIF uMsg == WM_KEYDOWN ; WM_KEY<blank> messages are always uppercase !
    ;    push wParam
    ;    pop char
    ;    invoke InvalidateRect, hWnd, NULL, TRUE
    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint,hWnd, ADDR ps
        mov    hdc,eax
        invoke FillRect, hdc, addr ps.rcPaint, COLOR_WINDOW+2
        
        RGB 250, 97, 100
        invoke SetBkColor, hdc, eax

        RGB 255, 255, 255
        invoke SetTextColor, hdc, eax

        invoke TextOutW,hdc,50,50,ADDR char,1
        invoke EndPaint,hWnd, ADDR ps
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
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax
end main