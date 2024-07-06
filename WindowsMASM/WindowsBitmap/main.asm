; THIS PROGRAM WILL SIMPLY
; DISPLAY A BITMAP FILE ONTO THE SCREEN
; 
; interestingly enough it is really simple
; to load and display a bitmap since we'll
; be using windows messages to send information between
; the client window and the memory device context
;
; -- also note how we're going to be using the
;		same boiler plate as in previous programs
;		it only differs in the handling of messages
.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib

WIDE MACRO varname:REQ, string:REQ, args:VARARG
    @CatStr(<&varname& WORD >, !', @SubStr(<&string&>, 2, 1), !')

    % FORC chr, <@SubStr(<&string&>, 3, @SizeStr(<&string&>)-3)>
        WORD '&chr&'
    ENDM

    FOR arg, <&args&>
        WORD &arg&
    ENDM
ENDM

wWinMain PROTO :DWORD, :DWORD, :DWORD, :DWORD
ID_MAIN equ 1

.data
WIDE ClassName, "SimpleWin32ASMBitmapClass", 0
WIDE AppName,   "Our ASM Bitmap Example", 0

.data?
hInstance   HINSTANCE ?
CommandLine     LPSTR ?
hBitmap     dd ?

.code
wWinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR,
            CmdShow:DWORD
    LOCAL wc:WNDCLASSEX
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    mov wc.cbSize, SIZEOF WNDCLASSEX
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL

    push  hInstance
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
    .while TRUE
        invoke GetMessageW, ADDR msg,NULL,0,0
        .break .if (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .endw
    mov     eax,msg.wParam
    ret
wWinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL ps:PAINTSTRUCT
    LOCAL hdc:HDC
    LOCAL hMemDC:HDC
    LOCAL rect:RECT

    .if uMsg == WM_CREATE
        ; upon recieving a create message
        ; let us firstly load up the bitmap .bmp file !
        invoke LoadBitmap, hInstance, ID_MAIN
        mov hBitmap, eax
    .elseif uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        
        invoke CreateCompatibleDC, hdc
        mov hMemDC, eax

        invoke SelectObject, hMemDC, hBitmap
        invoke GetClientRect, hWnd, addr rect

        invoke BitBlt, hdc, 0, 0, rect.right, rect.bottom, hMemDC, 0, 0, SRCCOPY
        invoke DeleteDC, hMemDC

        xor eax, eax
        invoke EndPaint, hWnd, addr ps
    .elseif uMsg == WM_DESTROY
        invoke DeleteObject, hBitmap
        invoke PostQuitMessage, NULL
    .else
        invoke DefWindowProcW, hWnd, uMsg, wParam, lParam
        ret
    .endif
    xor eax, eax
    ret
WndProc endp
main:
    invoke GetModuleHandle, NULL
    mov hInstance, eax

    invoke GetCommandLine
    mov CommandLine, eax

    invoke wWinMain, hInstance, NULL, CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess, eax
end main