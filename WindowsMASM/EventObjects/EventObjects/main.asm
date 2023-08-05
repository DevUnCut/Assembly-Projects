.386
.model flat, stdcall
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

.const
	IDM_START_THREAD equ 1
	IDM_STOP_THREAD equ 2
	IDM_EXIT equ 3
	WM_FINISH equ WM_USER+100h

.data
	WIDE ClassName, "ThreadClassWin32ASM",0
	WIDE AppName, "Win32 ASM MultiThreading Event Object handling",0
	WIDE MenuName, "MyMenu",0

	WIDE SuccessString, "The calculation is completed", 0
	WIDE UnsuccessfulString, "The calculation failed (-_-)", 0
	WIDE StopString, "Stopped the thread.", 0
	EventStop BOOL FALSE

.data?
	hInstance HINSTANCE ?
	CommandLine LPSTR ?
	hwnd HANDLE ?
	hMenu HANDLE ?

	ThreadID DWORD ?
	ExitCode DWORD ?
	hEventStart HANDLE ?

.code
wWinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
    LOCAL wc:WNDCLASSEXW ; create local variables onto the stack !
    LOCAL msg:MSG

    mov wc.cbSize, sizeof WNDCLASSEXW
    mov wc.lpfnWndProc, offset WndProc
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL

    push hInst
    pop wc.hInstance

    mov   wc.hbrBackground,COLOR_WINDOW+9
    mov   wc.lpszMenuName, offset MenuName
    mov   wc.lpszClassName,OFFSET ClassName

    invoke LoadIcon,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax

    invoke LoadCursor,NULL,IDC_ARROW
    mov   wc.hCursor,eax

    invoke RegisterClassExW, addr wc ; register our window class

    invoke CreateWindowExW, WS_EX_CLIENTEDGE,
            offset ClassName,
            offset AppName,
            WS_OVERLAPPEDWINDOW, ; The style of the window being created <read Windows 32 api for more details>
            CW_USEDEFAULT, ; x-coord
            CW_USEDEFAULT, ; y-coord
            300, ; width value
            200, ; height value
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

; NOW LET US DEFINE THE PROCESS (ROUTINE) THAT WE
; WANT A THREAD TO DO --- we are going to call it ThreadProc
;
; THIS IS WHERE A LOT OF OUR CHANGES TO PREVIOUS CODE FOUND IN Multithreading IS DONE
; ALONG AT THE WINDOW PROCRESS ROUTINE .... BUT FOR NOW LETS FOCOUS ON OUR ThreadProc routine !
ThreadProc PROC USES ecx Param:DWORD
    ; First change is that WE WANT (THIS BLOCK OF CODE SPECIFICILY)
    ; TO MAKE A CALL TO THE WaitForSingleObject() FUCT
    ; AND WAIT FOR THE EVENT STATUS BE THAT OF WHAT IS PASSED INTO THE ARGUMENT !
    invoke WaitForSingleObject, hEventStart, INFINITE ; we are going to infinently wait for the status of the event to be signalled ! !
    
    ; now lets reuse our old rutine of adding the
    ; eax register to itself 600,000,000 times ! !
    ;
    ; OHHHH SO THATS WHY THE PROC SAYS USES ECX BECAUSE
    ; WE ARE GOING TO MAKE USE OF THE ECX REGISTER AS OUR COUNTER ! !
    mov ecx, 600000000
    .WHILE ecx != 0
        .if EventStop != TRUE ; if the thread has not be flagged down to the nonsignalled state ! !
            add eax, eax
            dec ecx
        .else
            ; THE THREAD IS IN THE nonsignalled STATE ! !
            invoke MessageBoxW, hwnd, addr StopString, addr AppName, MB_OK
            mov EventStop, FALSE
            jmp ThreadProc
        .endif
    .ENDW
        invoke PostMessage, hwnd, WM_FINISH, NULL, NULL
        invoke EnableMenuItem, hMenu, IDM_START_THREAD, MF_ENABLED
        invoke EnableMenuItem, hMenu, IDM_STOP_THREAD, MF_GRAYED
        jmp ThreadProc
        ret
ThreadProc ENDP

; The only other location that will have minor changes is
; in our Window Procedure ... most of it is left the same
; again just slight changes which i will point out ! !
WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    ; first things first we need to create the event object
    ; it doesn't now that is what we want to do so we must
    ; override the what happens when we first create our window
    .IF uMsg == WM_CREATE
        ; now that we recieved the create window, windows message
        ; let us now create our event object for signalling !
        ;
        ; READ THE MICROSOFT WINDOWS 32 API DOCUMENTATION FOR FURTHER
        ; EXPLANATION ON HOW TO USE AND WHAT CreateEvent() RETURNS !
        invoke CreateEventW, NULL, FALSE, FALSE, NULL ; upon success this function returns a handle to the Event Object -- by convention
                                                      ; the returned data is stored within the eax register !
        mov hEventStart, eax

        ; the above just sets up our Event Object now lets
        ; set up our thread ! !
        mov eax, offset ThreadProc ; this is the routine that we want our thread to carry out !
        invoke CreateThread, NULL, NULL, eax,
                             NULL, 0,
                             addr ThreadID
        ; We are not using any handles in this program ....
        ; So close that handle that was opened from the CreateThread() function call
        invoke CloseHandle, eax
    .ELSEIF uMsg == WM_COMMAND
        mov eax, wParam
        .if lParam == 0
            .if ax == IDM_EXIT
                invoke PostQuitMessage, NULL
            .elseif ax == IDM_START_THREAD
                ; let us set the Event Object state to the signalled state
                invoke SetEvent, hEventStart
                ; and now let keep our user from selecting any other menu items
                ; we are going to grey out the start thread since its already started
                ; and we are going to leave the stop thread button enabled
                invoke EnableMenuItem, hMenu, IDM_START_THREAD, MF_GRAYED
                invoke EnableMenuItem, hMenu, IDM_STOP_THREAD, MF_ENABLED
            .elseif ax == IDM_STOP_THREAD
                mov EventStop, TRUE
                invoke EnableMenuItem, hMenu, IDM_START_THREAD, MF_ENABLED
                invoke EnableMenuItem, hMenu, IDM_STOP_THREAD, MF_GRAYED
            .else
                invoke DestroyWindow, hWnd
            .endif
        .endif
    .ELSEIF uMsg == WM_FINISH ; check for our custom windows message that we use
                              ; to communicate between threads (the User Interface thread and the Worker thread)
        invoke MessageBoxW, NULL, addr SuccessString, addr AppName, MB_OK
    .ELSE
        invoke DefWindowProcW, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
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