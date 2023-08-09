.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\comctl32.inc

includelib \masm32\lib\comctl32.lib
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
; let us define the IDs of our common controls
; which are const -- since their IDs do not change within this program !
    IDC_PROGRESS equ 1 ; ID for the Progress bar common control ! -- we are deciding to have it be 1 for this particular program
    IDC_STATUS   equ 2 ; ID for the Status bar common control   ! -- again we're deciding to have the status bar ID be 2 in this particular program
    IDC_TIMER   equ 3
.data
    WIDE ClassName,     "CommonControlWinClass", 0
    WIDE AppName,       "An Example of Common Controls", 0
    WIDE ProgressClass, "msctls_progress32", 0 ; the msctls_progress32 is the class name of the progress bar ! !
    WIDE Msg,           "Finished yeah ", 33, 0
    TimerID dd          0
.data?
    hInstance  HINSTANCE ?
    hwndProgress dd ?
    hwndStatus dd ?
    CurrentStep dd ?

.code
; Nearly all common controls are created by calling CreateWindowEx or CreateWindowExW, passing it the name of the control class.
; Some common controls have specific creation functions , however, they are just wrappers
; around the CreateWindowEx and CreateWindowExW processes to make it easier to create those controls.
;
; so with that being said most of our changes will happen here ! ! !
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

    mov   wc.hbrBackground,COLOR_APPWORKSPACE ; set the background color of our window !
    mov   wc.lpszMenuName, NULL
    mov   wc.lpszClassName,OFFSET ClassName

    invoke LoadIconW,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax

    invoke LoadCursorW,NULL,IDC_ARROW
    mov   wc.hCursor,eax

    invoke RegisterClassExW, addr wc
    ; here down below is where changes are made for our bread and butter routine !
    invoke CreateWindowExW, WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,
                            WS_OVERLAPPED+WS_CAPTION+WS_SYSMENU+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_VISIBLE,CW_USEDEFAULT,
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
; and whats coming more apparent is a lot of things are handled though the use of windows messages
;
; as stated before nearly all common controls are created by calling CreateWindowEx or CreateWindowExW, passing it the name of the control class.
; now those functions send a WM_CREATE message so lets use that has a communication way point
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL startInfo:STARTUPINFO ; we'll need this for our call to CreateProcess() ! !
    .IF uMsg == WM_CREATE
        ; lets create a child window which is going to be our progress bar !
        invoke CreateWindowExW, NULL,ADDR ProgressClass,NULL,
                               WS_CHILD+WS_VISIBLE,100,
                               200,300,20,hWnd,IDC_PROGRESS,
                               hInstance,NULL
        mov hwndProgress, eax ; lets make sure we store that handle to the window which contains our progress bar ! !

        mov eax, 1000 ; the lParam of PBM_SETRANGE message contains this range
        mov CurrentStep, eax
        shl eax, 16 ; shift eax register left 16-bits ... this is done to set the high range in the high word location !

        invoke SendMessage, hwndProgress, PBM_SETRANGE, 0, eax
        invoke SendMessage, hwndProgress, PBM_SETSTEP, 10, 0
        invoke CreateStatusWindowW, WS_CHILD+WS_VISIBLE, NULL, hWnd, IDC_STATUS

        mov hwndStatus, eax
        invoke SetTimer, hWnd,IDC_TIMER,100,NULL ; create a timer
        mov TimerID, eax
    .ELSEIF uMsg == WM_DESTROY
        invoke PostQuitMessage, NULL
        .if TimerID !=0
            invoke KillTimer, hWnd, TimerID ; do some clean up if the WM_DESTROY message is sent
        .endif
    .ELSEIF uMsg == WM_TIMER ; when the timer event occurs run this block of code
        invoke SendMessage, hwndProgress, PBM_STEPIT, 0, 0 ; step up the progress in the progress bar
        sub CurrentStep, 10
        .if CurrentStep == 0
            invoke KillTimer, hWnd, TimerID
            mov TimerID, 0
            invoke SendMessage, hwndStatus, SB_SETTEXT, 0, addr Msg
            invoke MessageBoxW, hWnd, addr Msg, addr AppName, MB_OK+MB_ICONINFORMATION

            invoke SendMessage, hwndStatus, SB_SETTEXT, 0, 0
            invoke SendMessage, hwndProgress, PBM_SETPOS, 0, 0
        .endif
    .ELSE
        invoke DefWindowProcW, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
    ret
WndProc endp

main:
    invoke GetModuleHandle, NULL
    mov    hInstance,eax
    invoke wWinMain, hInstance,NULL,NULL, SW_SHOWDEFAULT
    invoke ExitProcess,eax
    invoke InitCommonControls
end main