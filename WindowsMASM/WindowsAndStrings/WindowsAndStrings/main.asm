.386
.model flat,stdcall
option casemap:none

include S:\masm32\include\windows.inc

; calls to Windows functions in user32.lib and kernel32.lib
include S:\masm32\include\user32.inc
includelib S:\masm32\lib\user32.lib

include S:\masm32\include\kernel32.inc
includelib S:\masm32\lib\kernel32.lib

include S:\masm32\include\gdi32.inc ; Graphics Device Interface functions for SetTextColor & SetBkColor !
includelib S:\masm32\lib\gdi32.lib


WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

; let us write a macro that'll insert qutations and a comma for us so we can use a
; prettier looking unicode string
; this macro does not capture literal , ; : " . .... etc <use with care>
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
WIDE ClassName, "Simple Win Class", 0 ; the name of our window class - let us make use of our macro
;WIDE AppName, "hello", 0 ; The Window Title ! - lets make use of our macro so the unicode wide char string doesn't look ugly !
WIDE OurText, "im a unicode string ", 21h, 13, 10, 0
; "genki desu" japanese expression for how are you (health, mind, spirit) 
AppName word 4e93h, 6c17h, 3067h, 3059h, 0 ; The window_title ! 
FontName db "Times New Roman",0

.data?
hInstance HINSTANCE ? ; Instance handle of our program, we'll be storing the contents of a register that holds
                      ; all the data to our programs handle and store it there !
CommandLine LPSTR ?

.code
wWinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   To register a window class, we must fill in a WNDCLASSEXW structure                         ;
;   By first defining a local variable then filling in that structure with the desired data !   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LOCAL wc:WNDCLASSEXW ; create local variables onto the stack !
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    mov wc.cbSize, sizeof WNDCLASSEXW
    mov wc.lpfnWndProc, offset WndProc
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL

    push hInst
    pop wc.hInstance

    mov   wc.hbrBackground,COLOR_WINDOW+1
    mov   wc.lpszMenuName,NULL
    mov   wc.lpszClassName,OFFSET ClassName

    invoke LoadIcon,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax
    invoke LoadCursor,NULL,IDC_ARROW
    mov   wc.hCursor,eax

    invoke RegisterClassExW, addr wc                       ; register our window class

    invoke CreateWindowExW, WS_EX_CLIENTEDGE,
            offset ClassName,
            offset AppName,
            WS_OVERLAPPEDWINDOW, ; The style of the window being created <read Windows 32 api for more details>
            CW_USEDEFAULT, ; x-coord
            CW_USEDEFAULT, ; y-coord
            CW_USEDEFAULT, ; width value
            CW_USEDEFAULT, ; height value
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

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    ; we're going to be handling the WM_PAINT message and we'll need to be handling a PAINTSTRUCT so define a local variable !
    ; for that sturct that we'll be using along with other sturctures we might need !
    LOCAL ps:PAINTSTRUCT
    LOCAL hdc:HDC
    LOCAL box:RECT
    LOCAL hfont:HFONT
    .IF uMsg == WM_DESTROY ; if the user closes our window
        invoke PostQuitMessage,NULL ; quit our application
    .ELSEIF uMsg == WM_PAINT
        invoke BeginPaint, hWnd, addr ps
        mov hdc, eax
        ; All painting occurs here, between BeginPaint and EndPaint.
        invoke CreateFont, 24, 16, 0, 0, 400, 0, 0, 0,
                    OEM_CHARSET,
                    OUT_DEFAULT_PRECIS,
                    CLIP_DEFAULT_PRECIS,
                    DEFAULT_QUALITY,DEFAULT_PITCH or FF_SCRIPT,
                    ADDR FontName
        invoke SelectObject, hdc, eax
        mov    hfont,eax

        ; after defining our RGB struct using our macro that 32-bit struct will be stored in the eax register !
        RGB    147,200,70
        invoke SetTextColor,hdc,eax


        RGB    0,0,0 ; turn everything off 0, 0, 0 for black ! ! OR turn everything on 255, 255, 255 for white ! !
        invoke SetBkColor,hdc,eax

        invoke FillRect, hdc, addr ps.rcPaint, COLOR_WINDOW+2 ; set the background to gray !
        invoke GetClientRect,hWnd, ADDR box
        invoke DrawTextW, hdc,ADDR OurText,-1, ADDR box,
                DT_SINGLELINE or DT_CENTER or DT_VCENTER
        invoke EndPaint,hWnd, ADDR ps
    .ELSE
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; I THOUGHT I HAD A BUG WERE I WAS ONLY CAPTURING AND DISPLAYING THE FIRST UNICODE CHARACTER OF THE AppName WIDE STRING         ;
    ; COME TO FIND OUT I HAD CALLED THE DEFAULT DefWindowPro WHEN I SHOULD BE USING THE W VERSION SINCE IM WORKING WITH WIDE CHARS  ;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        invoke DefWindowProcW,hWnd,uMsg,wParam,lParam     ; Default message processing
        ret
    .ENDIF
    xor eax,eax
    ret
WndProc endp

main:
    ; get the instance handle of our program.
    invoke GetModuleHandleW, NULL

    ; Under Win32, hmodule==hinstance ... SOOOO mov hInstance,eax will do the trick !
    mov hInstance,eax

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; get the command line. You don't have to call this function    ;
    ; IF your program doesn't process the command line.             ;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    invoke GetCommandLineW
    mov CommandLine,eax

    ; call the wWinMain entry point to all windows based applications ! !
    invoke wWinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; quit our program. with the exitCode set to the value that we get after running the wWinMain function,     ;
    ; which is stored in the eax register by default unless otherwise specified !                               ;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    invoke ExitProcess, eax
end main