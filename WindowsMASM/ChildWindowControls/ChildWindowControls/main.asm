.386
.model flat, stdcall
option casemap:none

wWinMain proto :DWORD,:DWORD,:DWORD,:DWORD

include S:\masm32\include\windows.inc
include S:\masm32\include\kernel32.inc
include S:\masm32\include\user32.inc

includelib S:\masm32\lib\kernel32.lib
includelib S:\masm32\lib\user32.lib

.data
ClassName word 'W','i','n','C','l','a','s','s',0
windowName word 4e93h, 6c17h, 3067h, 3059h, 0
MenuName db "FirstMenu",0
; how would the window that will contain our text fill in box look
; like if we add a name to the window just like how we have for our main
; progam window which is the japanese expression "genki desu" ? ?
; long story short ... it just fills in text input box with Window Name string parameter !
;editWindow_name word 4e93h, 6c17h, 3067h, 3059h, 0

; question to self .... do all child windows just create input dialog windows ? .....
; ############ ... REMEMBER THE READING FROM THE WINDOWS 32 API {} ##################################################
; # if we would like to use a predefined child window class SPECIFY IT within the class name parameter ! ! ##########
; # for ex. if we would like to create a button, we must specify "button" as the class name in CreateWindowEx ! ! ###
; ###################################################################################################################
ClassName_EDIT_button word 'e','d','i','t',0

ButtonClassName word 'b','u','t','t','o','n',0 ; lets try and use that button ex from above in a real life ex !
ButtonText word 79c1h, 306eh,'B','u','t','t','o','n',0
TestString word 'W','o','w','!',0

text db "Windows Assembly is so fun !", 0
winName db "My Window", 0
.data?
; Instance handle of our program
hInstance HINSTANCE ?
CommandLine LPSTR ?
hwndEdit HWND ? ; this variable will contain the handle to our Edit child window which
                ; will create an input window for a user to input text into our program !

hwndButton HWND ? ; handle to the Button Child window !
buffer dw 512 dup(?) ; this variable will hold the text our user
                     ; will input into our edit child window ! !

.const
EditID equ 2 
ButtonID equ 1

; menu stuff below
IDM_HELLO equ 1
IDM_CLEAR equ 2
IDM_GETTEXT equ 3
IDM_EXIT equ 4
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
    mov   wc.hbrBackground,COLOR_WINDOW+1
    mov   wc.lpszMenuName, offset MenuName
    mov   wc.lpszClassName,OFFSET ClassName

    invoke LoadIconW,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax

    invoke LoadCursorW,NULL,IDC_ARROW
    mov   wc.hCursor,eax

    ; register our window class
    invoke RegisterClassExW, addr wc

    invoke CreateWindowExW,NULL,
                ADDR ClassName,
                ADDR windowName,
                WS_OVERLAPPEDWINDOW,
                CW_USEDEFAULT,
                CW_USEDEFAULT,
                CW_USEDEFAULT,
                CW_USEDEFAULT,
                NULL,
                NULL,
                hInst,
                NULL
    mov   hwnd,eax

    ; display our window on desktop
    invoke ShowWindow, hwnd,CmdShow
    ; refresh the client area
    invoke UpdateWindow, hwnd

    .WHILE TRUE ; Enter message loop
                invoke GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
   .ENDW
    mov     eax,msg.wParam ; return exit code in eax
    ret
wWinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
; we are able to create child windows controls but it must be done during window creation !
; so let us use the WM_CREATE message to flag down the creation of the window !
    .if uMsg == WM_DESTROY
        invoke PostQuitMessage, NULL
    .elseif uMsg == WM_CREATE ; in the creation of window !
        invoke CreateWindowExW,WS_EX_DLGMODALFRAME, ; this invoke will create the input dialog child window !
                ADDR ClassName_EDIT_button, NULL,   ;addr editWindow_name,
                WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_AUTOHSCROLL,
                50,35,200,25,hWnd,EditID,hInstance,NULL
        mov  hwndEdit,eax
        invoke SetFocus, hwndEdit   ; Sets the keyboard focus to the specified window.
                                    ; The window must be attached to the calling thread's message queue.

        invoke CreateWindowExW,NULL, ADDR ButtonClassName,ADDR ButtonText, WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,
                        75,70,140,25,hWnd,ButtonID,hInstance,NULL
        mov  hwndButton,eax
    .ELSEIF uMsg==WM_COMMAND
        mov eax,wParam

        ; was trying to figure out how the below code works but finally figured out
        ; we only enter the following when we're not a child window and the logic code of once
        ; the user presses the button send the WM_COMMAND message with just the
        ; IDM_GETTEXT and nothing else, with the wParam set to IDM_GETTEXT & lParam set to zero 0 ! !

        .IF lParam==0 ;  check lParam. If it's zero, the current WM_COMMAND message is from a menu
            .IF ax==IDM_HELLO ; display our text to the screen !
                invoke SetWindowTextW,hwndEdit,ADDR TestString ; fill in window with TestString !
            .ELSEIF ax==IDM_CLEAR
                invoke SetWindowTextW,hwndEdit,NULL
            .ELSEIF  ax==IDM_GETTEXT
                invoke GetWindowTextW,hwndEdit,ADDR buffer,512
                invoke MessageBoxW,NULL,ADDR buffer,ADDR windowName,MB_OK
            .ELSE
                invoke DestroyWindow,hWnd
            .ENDIF
        .ELSE ; else were not a window so we're a child window control ! (in this ex yes, but can be other things too)
            .IF ax==ButtonID
                shr eax,16
                .IF ax==BN_CLICKED
                    invoke SendMessageW, hWnd, WM_COMMAND, IDM_GETTEXT, 0 ; get user input first then
                    invoke SendMessageW, hWnd, WM_COMMAND, IDM_HELLO, 0   ; send "Wow" to edit window next !
                    invoke MessageBoxA, hWnd, addr text, addr winName, NULL
                    ;invoke SendMessageW, hWnd, WM_COMMAND, IDM_CLEAR, 0 ; happens so fast we never see the text in window
                .ENDIF
            .ENDIF
        .ENDIF
    .ELSE
        invoke DefWindowProcW, hWnd, uMsg, wParam, lParam
    .endif
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