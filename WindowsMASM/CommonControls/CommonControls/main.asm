.386
.model flat, stdcall
option casemap:none

wWinMain proto :DWORD,:DWORD,:DWORD,:DWORD

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\comctl32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\comctl32.lib

.const
; the following variables will contain
; all of the id's needed to call a
; specific common control specified in the
; comctl32.lib --- reference win 32 api for more info

IDC_PROGRESS equ 1
IDC_STATUS	equ 2
IDC_TIMER	equ 3

.data
ClassName		word 'C','o','m','m','o','n','C','o','n','t','r','o','l','W','i','n','C','l','a','s','s', 0
WinName			word 'C','o','m','m','o','n',' ','C','o','n','t','r','o','l','s',' ','E','x','a','m','p','l','e',0
ProgressClass	word 'm','s','c','t','l','s','_','p','r','o','g','r','e','s','s','3','2',0

Message			word 4e93h, 6c17h, 3067h, 3059h, 0b
TimerID			dd 0

.data?
hInstance		HINSTANCE ?
hwndProgress	dd ?
hwndStatus		dd ?
CurrentStep		dd ?

.code
wWinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:PWSTR,CmdShow:DWORD
    ; create local variables on stack
    LOCAL wc:WNDCLASSEXW
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    ; fill values in members of wc
    mov   wc.cbSize,SIZEOF WNDCLASSEXW
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL
    push  hInstance
    pop   wc.hInstance
    mov   wc.hbrBackground,COLOR_APPWORKSPACE
    mov   wc.lpszMenuName, NULL
    mov   wc.lpszClassName,OFFSET ClassName

    invoke LoadIconW,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax

    invoke LoadCursorW,NULL,IDC_ARROW
    mov   wc.hCursor,eax

    ; register our window class
    invoke RegisterClassExW, addr wc

    invoke CreateWindowExW,WS_EX_CLIENTEDGE,
                ADDR ClassName, ADDR WinName,
                WS_OVERLAPPED+WS_CAPTION+WS_SYSMENU+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_VISIBLE,
                CW_USEDEFAULT,
                CW_USEDEFAULT,
                CW_USEDEFAULT,CW_USEDEFAULT,
                NULL,NULL,
                hInst,NULL
    mov   hwnd,eax

    .WHILE TRUE ; Enter message loop
                invoke GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
   .ENDW
    mov     eax,msg.wParam ; return exit code in eax
    ret
wWinMain endp


; seems like a rinse and repeat to what we are used
; except this time we are going to be communicating
; to the common control window via WM_NOTIFY messages
; and not WM_COMMAND messages since we cant command these windows
WndProc proc  hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .if uMsg==WM_CREATE
         ; The following code bellow will create and display our progress bar ... like
         ; the ones we see when moving files.


         ; All child window controls must have WS_CHILD style.
         ; this hWnd is the parent window handle of the child window we are creating
         ; and IDC_PROGRESS is the id of the control we want to use. Also since we
         ; have the child window control handle the IDC_PROGRESS will not be used !
         invoke CreateWindowExW,NULL,ADDR ProgressClass,NULL,
            WS_CHILD+WS_VISIBLE,100, 
            200,300,20,hWnd,IDC_PROGRESS, 
            hInstance,NULL
        mov hwndProgress,eax

        ; After the progress bar is created, we can set its range. The default range is from 0 to 100.
        ; we can set up our own custom range via the PBM_SETRANGE message ! !
        ; the lParam of PBM_SETRANGE message contains the range
        mov eax,1000 ; lets define the total time for the progress bar
        mov CurrentStep,eax
        shl eax,16                   ; the maximum range of the progress bar is in the high word of PBM_SETRANGE
                                     ; while the minimum range of the progress bar is stored in the low word of PBM_SETRANGE !

        invoke SendMessage,hwndProgress,PBM_SETRANGE,0,eax
        invoke SendMessage,hwndProgress,PBM_SETSTEP,10,0 ; here we are letting the parent window know how much of a step we'll be taking by using PBM_SETSTEP message.
        ; Now that our step size is set, this means that when you send a PBM_STEPIT message to the progress bar,
        ; the progress bar indicator will rise by 10. You can also set your own indicator level by sending PBM_SETPOS messages.
        ; This message (PBM_SETPOS) gives you tighter control over the progress bar.

        ; now we are ready to create and display the status bar, my invoking the CreateStatusWindowW function 
        invoke CreateStatusWindowW,WS_CHILD+WS_VISIBLE,NULL,hWnd,IDC_STATUS
        mov hwndStatus,eax

        ; After the status window is created, we can create a timer.
        invoke SetTimer,hWnd,IDC_TIMER,100,NULL        ; create a timer
        mov TimerID,eax
        ; we will update the progress bar at a regular interval of 100 ms so we must create a timer control -- not done here --
    .elseif uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL
        .if TimerID!=0
            invoke KillTimer,hWnd,TimerID
        .endif
    ; When the specified time interval expires, the timer sends a WM_TIMER message.
    ; You will put our code that we want to be executed in here ! In this example, we'll update the progress bar and then check if the maximum limit has been reached.
    ; If it has, we kill the timer and then set the text in the status window with SB_SETTEXT message.
    ; A message box is displayed and when the user clicks OK, we clear the text in the status bar and the progress bar.
    .elseif uMsg==WM_TIMER        ; when a timer event occurs
        invoke SendMessage,hwndProgress,PBM_STEPIT,0,0    ; step up the progress in the progress bar
        sub CurrentStep,10
        .if CurrentStep==0
            invoke KillTimer,hWnd,TimerID
            mov TimerID,0
            invoke SendMessage,hwndStatus,SB_SETTEXT,0,addr Message
            invoke MessageBoxW,hWnd,addr Message,addr WinName,MB_OK+MB_ICONINFORMATION
            invoke SendMessage,hwndStatus,SB_SETTEXT,0,0
            invoke SendMessage,hwndProgress,PBM_SETPOS,0,0
        .endif
    .else
        invoke DefWindowProcW,hWnd,uMsg,wParam,lParam
        ret
    .endif
    xor eax,eax
    ret
WndProc endp


main:
    invoke GetModuleHandle, NULL
    mov    hInstance,eax
    invoke wWinMain, hInstance,NULL,NULL, SW_SHOWDEFAULT
    invoke ExitProcess,eax
    invoke InitCommonControls
end main