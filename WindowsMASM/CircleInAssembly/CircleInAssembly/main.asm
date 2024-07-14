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

.data
    WIDE ClassName, "CircleWndClass",0
	WIDE AppName, "Circle GFX In Assembly", 0

    DlgHeight DWORD 0
	DlgWidth DWORD 0

.data?
    ; variables for our window !
	hInstance HINSTANCE ?
	CommandLine LPSTR ?
	hwnd HANDLE ?
    hBrush HBRUSH ?

.code
wWinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
    ; lets set up the variables we need for our window !
    LOCAL wc:WNDCLASSEXW
    LOCAL msg:MSG

    mov   wc.cbSize,SIZEOF WNDCLASSEXW
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL

    push  hInst
    pop   wc.hInstance

    mov   wc.hbrBackground,COLOR_WINDOW+2 ; set the background color of our window !
    mov   wc.lpszMenuName, NULL
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
    mov hwnd, eax
    invoke ShowWindow, hwnd,SW_SHOWNORMAL
    invoke UpdateWindow, hwnd

    ; the following is new code additions !
    .WHILE TRUE
        invoke GetMessageW, ADDR msg,NULL,0,0
        .BREAK .IF (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW

    mov     eax,msg.wParam
    ret
wWinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL ps:PAINTSTRUCT
    LOCAL hdc:HDC
    LOCAL rect:RECT
    LOCAL hOldRect:DWORD

    LOCAL xLeftTop:DWORD
    LOCAL yLeftTop:DWORD
    LOCAL xRightBot:DWORD
    LOCAL yRightBot:DWORD

    .if uMsg == WM_SIZE
        invoke GetWindowRect, hWnd, addr rect
        ; lets get the height of the newly resized client window ! !
		mov eax, rect.bottom
		sub eax, rect.top
		mov DlgHeight, eax

        ; lets get the width of the newly resized client window ! !
		mov eax, rect.right
		sub eax, rect.left
		mov DlgWidth, eax
    .elseif uMsg == WM_PAINT
        ; lets define the area we want to
        ; display the circle at !
        ; here we are to display a circle that is
        ; 1/4 top and bottom of the total client window
        ; and is 1/3 left and right of the total client window
        mov eax, DlgHeight
        mov ebx, 4
        xor edx, edx
        div ebx
        mov yRightBot, eax

        mov eax, DlgHeight
        sub eax, yRightBot
        mov yLeftTop, eax

        mov eax, DlgWidth
        mov ebx, 3
        xor edx, edx
        div ebx
        mov xLeftTop, eax

        mov eax, DlgWidth
        sub eax, xLeftTop
        mov xRightBot, eax

        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax

        ; grab a handle to one of the stock pens, brushes, fonts, or palettes.
        invoke GetStockObject, DC_BRUSH
        mov hBrush, eax
        
        ; now we can select the newly created brush
        invoke SelectObject, hdc, hBrush
        mov hOldRect, eax       ; save the old client rectangle
        
        ; now we are able to finally change the brush color before we call the rectangle we want to fill
        ; in this case we are going to be using the hex color code value to set the brush color and then
        ; we can call the shape we want to draw to the defined space
        invoke SetDCBrushColor, hdc,00ff0fh
        invoke Ellipse, hdc,xLeftTop, yLeftTop, xRightBot, yRightBot

        invoke DeleteDC, hdc
        invoke DeleteObject, hBrush
        xor eax, eax
        invoke EndPaint, hWnd, addr ps
    .elseif uMsg == WM_DESTROY
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
    mov    hInstance,eax
    invoke GetCommandLine
    mov CommandLine,eax
    invoke wWinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax
end main