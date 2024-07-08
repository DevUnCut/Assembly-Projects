;--------------------------------------------------------------------------
; The main driver program that uses the SPLASH.DLL to show a Splash Screen
;--------------------------------------------------------------------------
.386
.model flat,stdcall
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

wWinMain proto :DWORD, :DWORD, :DWORD, :DWORD

.data
WIDE ClassName, "SplashWindowDemoClass", 0
WIDE WindowName, "Our custom Splash Screen", 0

WIDE LibName, "splash.dll", 0

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?

.code
wWinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
 LOCAL wc:WNDCLASSEX
 LOCAL msg:MSG
 LOCAL hwnd:HWND

 mov   wc.cbSize,SIZEOF WNDCLASSEX
 mov   wc.style, CS_HREDRAW or CS_VREDRAW
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
 invoke CreateWindowExW,NULL,ADDR ClassName,ADDR WindowName,
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
 .if uMsg == WM_DESTROY
    invoke PostQuitMessage,NULL
 .else
    invoke DefWindowProcW,hWnd,uMsg,wParam,lParam
    ret
 .endif
 xor eax,eax
 ret
WndProc endp

main:
    invoke LoadLibraryW,addr LibName
    .if eax!=NULL
        invoke FreeLibrary,eax
    .endif

    invoke GetModuleHandle, NULL
    mov    hInstance,eax
    invoke GetCommandLine
    mov    CommandLine,eax
    invoke wWinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax
end main