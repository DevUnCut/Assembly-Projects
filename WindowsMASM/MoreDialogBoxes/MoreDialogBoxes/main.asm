;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; In this program let us make use of the common dialog boxes that Windows                                ;
; provides for us within the comdlg32.dll library ! !                                                    ;
; The goal here is to get an understanding on how to use them, lets                                      ;
; start by writing a program that'll, display an open file dialog box when                               ;
; the user selects File-> Open from the menu. When the user selects a file in the dialog box,            ;
; the program displays a message box showing the full name, filename,and extension of the selected file. ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.386
.model flat,stdcall
option casemap:none

; lets make it easier to fill in our wide strings (unicode) with this macro !
WIDE MACRO varname:REQ, string:REQ, args:VARARG
    @CatStr(<&varname& WORD >, !', @SubStr(<&string&>, 2, 1), !')

    % FORC chr, <@SubStr(<&string&>, 3, @SizeStr(<&string&>)-3)>
        WORD '&chr&'
    ENDM
        FOR arg, <&args&>
        WORD &arg&
    ENDM
ENDM
; our macro does not capture exclamation marks '!' use with care ! !

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\comdlg32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\comdlg32.lib

.const
; Menu selection constants !
ID_FILE equ 1
ID_EXIT equ 2

; file size constants !
MAXSIZE equ 260
OUTPUTSIZE equ 512

.data
WIDE ClassName,"WinClass",0
WIDE AppName, "My Selection",0

; the string we are to display our user once they click on the file menu button !
WIDE fileStr, "The next window allows you to select a file", 0
WIDE FileWinName,"Select a File", 0

WIDE WinName, "Select a File ", 33, ":", 0, 0
; since our user will have to select the File tab in our menu, we must create that menu first !\
WIDE MenuName,"MyMenu",0

; the following declarations are for file handling !
ofn   OPENFILENAMEW <>

; let us define an array that'll filter out our results, we can think of it the same as REGULAR EXPESSIONS !
FilterString word 'A','l','l',' ','F','i','l','e','s',0,'*','.','*',0
             word 'T','e','x','t',' ','F','i','l','e','s',0,'*','.','t','x','t',0 ,0
; Dont forget to flag down the end of the filter string with another null terminator '0'
; if we forget this our dialog box will behave strangely.
buffer word MAXSIZE dup(0)
WIDE OurTitle,"My First Open File Dialog Box: Choose the file to open",0
WIDE FullPathName, "The Full Filename with Path is: ",0
WIDE FullName, "The Filename is: ",0
WIDE ExtensionName, "The Extension is: ",0
OutputString word OUTPUTSIZE dup(?)
CrLf word 0Dh,0Ah,0

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?

.code

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
    ; lets start with all of our regular house keeping stuff so we can display a window to our user !
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

    mov   wc.hbrBackground,COLOR_WINDOW+2
    mov   wc.lpszMenuName,offset MenuName
    mov   wc.lpszClassName,OFFSET ClassName

    invoke LoadIconW,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax

    invoke LoadCursorW,NULL,IDC_ARROW
    mov   wc.hCursor,eax

    invoke RegisterClassExW, addr wc
    invoke CreateWindowExW,WS_EX_CLIENTEDGE,ADDR ClassName,ADDR AppName,
           WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,
           CW_USEDEFAULT,300,200,NULL,NULL,
           hInst,NULL
    mov   hwnd,eax

    invoke ShowWindow, hwnd,SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    ; enter the following infinite message loop !
    .WHILE TRUE
        invoke GetMessage, ADDR msg,NULL,0,0
        .BREAK .IF (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW
    mov     eax,msg.wParam
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .if uMsg == WM_DESTROY
        invoke PostQuitMessage, NULL
    .elseif uMsg == WM_COMMAND
        mov eax, wParam
        .if ax == ID_EXIT
            invoke ExitProcess, 0
        .elseif ax == ID_FILE
            ; lets start off by giving our user a message first of whats going to happen !
            invoke MessageBoxW, hWnd, offset fileStr, offset FileWinName, NULL
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Since we want to use the Open File Dialog Box, we must fill in     ;
            ; the OpenFileName structure, which more info can be found in the    ;
            ; windows 32 api documentation !                                     ;
            ; Once that OpenFileName struct has been filled we can call upon the ;
            ; GetOpenFileName function ! !                                       ;
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            mov ofn.lStructSize,SIZEOF ofn

            push hWnd
            pop  ofn.hwndOwner

            push hInstance
            pop  ofn.hInstance

            mov  ofn.lpstrFilter, OFFSET FilterString
            mov  ofn.lpstrFile, OFFSET buffer
            mov  ofn.nMaxFile,MAXSIZE

            mov  ofn.Flags, OFN_FILEMUSTEXIST or\
                OFN_PATHMUSTEXIST or OFN_LONGNAMES or\
                OFN_EXPLORER or OFN_HIDEREADONLY

            mov  ofn.lpstrTitle, OFFSET OurTitle
            invoke GetOpenFileNameW, ADDR ofn
            .if eax==TRUE
                ; let us concatonate some strings since we want
                ; to show the user what they've choosen ! !
                invoke lstrcatW,offset OutputString,OFFSET FullPathName
                invoke lstrcatW,offset OutputString,ofn.lpstrFile
                
                ; add in a new line with carriage return !
                invoke lstrcatW,offset OutputString,offset CrLf
                invoke lstrcatW,offset OutputString,offset CrLf

                invoke lstrcatW,offset OutputString,offset FullName
                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                ; nFileExtention. The zero-based offset, in characters,         ;
                ; from the beginning of the path to the file name extension     ;
                ; For the ANSI version, this is the number of bytes             ;
                ; For the Unicode version, this is the number of characters.    ;
                ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     
                mov eax, ofn.lpstrFile
                mov bx, ofn.nFileOffset
                L1:
                    ; we're dealing with unicode strings, which are 2 bytes per character ! !
                    add eax, 2
                    dec bx
                    cmp bx, 0
                    jne L1
                invoke lstrcatW, offset OutputString, eax
                invoke lstrcatW, offset OutputString, offset CrLf
                invoke lstrcatW, offset OutputString, offset CrLf

                invoke lstrcatW, offset OutputString,offset ExtensionName
                mov eax, ofn.lpstrFile
                mov bx, ofn.nFileExtension
                L2:
                    add eax, 2
                    dec bx
                    cmp bx, 0
                    jne L2
                invoke lstrcatW,offset OutputString, eax
                invoke MessageBoxW,hWnd,OFFSET OutputString,ADDR WinName,MB_OK
                invoke RtlZeroMemory,offset OutputString,OUTPUTSIZE
            .endif
        .endif
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
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax
end main