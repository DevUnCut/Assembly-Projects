.386
.model flat, stdcall
option casemap:none

WIDE MACRO varname:REQ, string:REQ, args:VARARG
    @CatStr(<&varname& WORD >, !', @SubStr(<&string&>, 2, 1), !')

    % FORC chr, <@SubStr(<&string&>, 3, @SizeStr(<&string&>)-3)>
        WORD '&chr&'
    ENDM

    FOR arg, <&args&>
        WORD &arg&
    ENDM
ENDM

include S:\masm32\include\windows.inc

include S:\masm32\include\user32.inc
includelib S:\masm32\lib\user32.lib

include S:\masm32\include\gdi32.inc
includelib S:\masm32\lib\gdi32.lib

include S:\masm32\include\kernel32.inc
includelib S:\masm32\lib\kernel32.lib

wWinMain PROTO :DWORD, :DWORD, :DWORD, :DWORD

.data
MouseClick db 0         ; 0=no click yet
ClassName word 'm','y','C','l','a','s','s',0
AppName word 'k', 'o', 'n','i','c','h','i','w','a', 0
txt word 4e93h, 6c17h, 3067h, 3059h, 0 ; The window_title ! 

WIDE mouseLMsg, "Left mouse button pressed ", 0
WIDE mouseRMsg, "Right mouse button pressed ", 0

.data?
    Hinstance           HINSTANCE ?
    CommandLine         LPSTR ?
    coordinates         POINT <>

.code
    wWinMain PROC hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
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

        ; the following is new code additions !
        .WHILE TRUE
            invoke GetMessageW, ADDR msg,NULL,0,0
            .BREAK .IF (!eax)
            invoke DispatchMessageW, ADDR msg
        .ENDW
        mov     eax,msg.wParam
        ret
    wWinMain endp


    WndProc PROC hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
        LOCAL ps:PAINTSTRUCT
        LOCAL hdc:HDC
        LOCAL box:RECT

        ; Lets begin by painting the Window onto the screen !
        .if uMsg == WM_DESTROY
            invoke PostQuitMessage, NULL
        .elseif uMsg == WM_PAINT
            invoke BeginPaint, hWnd, addr ps
            mov hdc, eax
            invoke FillRect, hdc, addr ps.rcPaint, COLOR_WINDOW+2 ; set the background to gray !

            .IF MouseClick
                invoke lstrlen,ADDR AppName
                invoke TextOut,hdc,coordinates.x,coordinates.y,ADDR AppName,eax
            .ENDIF

            invoke TextOutW, hdc, 0, 0, ADDR txt, 5
            invoke EndPaint,hWnd, ADDR ps
        .elseif uMsg == WM_LBUTTONDOWN
            mov eax, lParam
            ; at the momemnt we're only interested in the x-coord and it belongs to
            ; the POINT struct which contains two INT's x and y ... both 2 bytes
            ; leads to a total of 4 bytes or 32 bits, so we must zero out high word for a total of 16 bits !
            mov eax, lParam
            and eax, 0FFFFh
            mov coordinates.x, eax

            ; we've got our x but we've jumbled up the eax register,
            ; so let us throw lParam back in there !
            mov eax, lParam
            ; now we're focused on the higher 16 bits, but we're
            ; pointing at the fisrt bit so let us shift 16 bits to the right
            ; (meaning we're incresing in size !)
            shr eax, 16 
            mov coordinates.y, eax
            mov MouseClick, TRUE
            invoke InvalidateRect,hWnd,NULL,TRUE
            invoke MessageBoxW, hWnd, offset mouseLMsg, offset txt, MB_OK
        .elseif uMsg == WM_RBUTTONDOWN
            mov eax, lParam
            ; at the momemnt we're only interested in the x-coord and it belongs to
            ; the POINT struct which contains two INT's x and y ... both 2 bytes
            ; leads to a total of 4 bytes or 32 bits, so we must zero out high word for a total of 16 bits !
            mov eax, lParam
            and eax, 0FFFFh
            mov coordinates.x, eax

            ; we've got our x but we've jumbled up the eax register,
            ; so let us throw lParam back in there !
            mov eax, lParam
            ; now we're focused on the higher 16 bits, but we're
            ; pointing at the fisrt bit so let us shift 16 bits to the right
            ; (meaning we're incresing in size !)
            shr eax, 16 
            mov coordinates.y, eax
            mov MouseClick, TRUE
            invoke InvalidateRect,hWnd,NULL,TRUE
            invoke MessageBoxW, hWnd, offset mouseRMsg, offset txt, MB_OK
        .else
            invoke DefWindowProcW,hWnd, uMsg, wParam, lParam
        .endif
        ret
    WndProc endp

    main:
        ; We need to get a handle to our program instance ! so lets do just that !
        invoke GetModuleHandle, NULL ; the return value of this function is stored within the eax register !
        mov Hinstance, eax

        invoke GetCommandLine
        mov CommandLine, eax


        invoke wWinMain, Hinstance, NULL, CommandLine, SW_SHOWDEFAULT
        invoke ExitProcess, eax
    end main