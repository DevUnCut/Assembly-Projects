; The example will display a dialog box with three edit controls that is to be filled with the class name, window handle and the address of the window procedure associated with the window under the mouse cursor.
; There are two buttons, Hook and Exit.
; When you press the Hook button, the program hooks the mouse input and the text on the button changes to Unhook.
; When you move the mouse cursor over a window, the info about that window will be displayed in the main window of the example.
; When you press Unhook button, the program removes the mouse hook.
.386
.model flat,stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include DLL_Hook.inc

includelib HookDLL.lib
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib

wsprintfW proto C :VARARG
wsprintf TEXTEQU <wsprintfW>

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
ID_MAINDLG                  equ 101
ID_CLASSNAME                equ 1000
ID_HANDLE                   equ 1001         ; THIS VARIABLE WILL BE THE ID TO THE HANDLE OF THE DIALOG BOX
ID_WNDPROC                  equ 1002
ID_HOOK                     equ 1004
ID_EXIT                     equ 1005
WM_MOUSEHOOK                equ WM_USER+6 ; the windows message we want to handle windows has various address ranges that are used to 
                                          ; define private messages for use by private window classes, usually of the form WM_USER+x, where x is an integer value.
                                          ; and in our case WM_USER (+) through 0x7FFF are all Integer messages for use by private window classes ... refer to win 32 api for more info

DlgFunc PROTO :DWORD, :DWORD, :DWORD, :DWORD

.data
HookFlag dd FALSE                   ; this will tell us the state of the hook
WIDE HookText, "&Hooked", 0         ; the message we'll display once a hook is installed !!
WIDE UnhookText, "&Unhooked", 0     ; the message we'll display once the hook is uninstalled !!
WIDE template, "%lx", 0             ; we want our string to be formatted in this way !
;WIDE LibName, "DLL_Hook.dll"
.data?
hInstance   dd ?
hHook       dd ?

.code
; OUR MAIN PROGRAM WILL BE USING THE DIALOG BOX AS ITS MAIN WINDOW .... recall that we've done an application on
; using the dialog box as the main window also an important thing to note is that
; we'll be defining a custom windows message as noted above, WM_MOUSEHOOK which will be used between the main program and the hook DLL.
; When the main program receives this message, wParam contains the handle of the window that the mouse cursor is on.
; having the handle of the window being located in wParam is arbitrary because I DECIDED TO SEND the handle in wParam for the sake of simplicity.
; but we can choose our own method of communication between the main program and the hook DLL.

DlgFunc proc hDlg:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
    LOCAL hLib:DWORD                ; handle to the dll library we are going to use .... this example will be a remote dll
    LOCAL buffer[128]:byte
    LOCAL buffer1[128]:byte
    LOCAL rect:RECT                 ; variable to store a rectangle ... we'll use the GetWindowRect

    .if uMsg == WM_CLOSE            ; if we get a message to close the application then check if we have a hook installed
        .if HookFlag == TRUE        ; THE HOOK IS CURRENTLY INSTALLED SO LETS UNINSTALL IT
            invoke UninstallHook    ; this function definition is in the hook's dll file
        .endif
        invoke EndDialog, hDlg, NULL
    .elseif uMsg == WM_INITDIALOG   ; here is where we'll setup the dialog box
        ;  lets call GetWindowRect to get the dimensions of the bounding rectangle for the specified window
        invoke GetWindowRect, hDlg, addr rect
        invoke SetWindowPos, hDlg, HWND_TOPMOST, rect.left, rect.top, rect.right, rect.bottom, SWP_SHOWWINDOW
    ; next lets handle our custom message that we defined above in our .const section
    .elseif uMsg == WM_MOUSEHOOK
        ; lets start off by getting the handle to the window we have under the cursor
        invoke GetDlgItemTextW, hDlg, ID_HANDLE, addr buffer1, 128
        invoke wsprintf, addr buffer, addr template, wParam
        invoke lstrcmpiW,addr buffer, addr buffer1
        .if eax != 0
            invoke SetDlgItemTextW, hDlg, ID_HANDLE, addr buffer
        .endif

        ; now we can continue on to getting the window class name
        invoke GetDlgItemTextW, hDlg, ID_CLASSNAME, addr buffer1, 128
        invoke GetClassNameW, wParam, addr buffer, 128
        invoke lstrcmpiW, addr buffer, addr buffer1
        .if eax != 0
            invoke SetDlgItemTextW, hDlg, ID_CLASSNAME, addr buffer
        .endif

        invoke GetDlgItemTextW, hDlg, ID_WNDPROC, addr buffer1, 128
        invoke GetClassLongW, wParam, GCL_WNDPROC
        invoke wsprintf, addr buffer, addr template, eax
        invoke lstrcmpiW, addr buffer, addr buffer1
        .if eax != 0
            invoke SetDlgItemTextW, hDlg, ID_WNDPROC, addr buffer
        .endif
    .elseif uMsg == WM_COMMAND
        .if lParam != 0
            mov eax, wParam
            mov edx, eax
            shr edx, 16
            .if dx == BN_CLICKED
                .if ax == ID_EXIT
                    invoke SendMessageW, hDlg, WM_CLOSE, 0, 0
                .else
                    .if HookFlag == FALSE
                        invoke InstallHook, hDlg
                        .if eax != NULL
                            mov HookFlag, TRUE
                            invoke SetDlgItemTextW, hDlg, ID_HOOK, addr UnhookText
                        .endif
                    .else
                        invoke UninstallHook
                        invoke SetDlgItemTextW, hDlg, ID_HOOK, addr HookText
                        mov HookFlag, FALSE

                        invoke SetDlgItemTextW, hDlg, ID_CLASSNAME, NULL
                        invoke SetDlgItemTextW, hDlg, ID_HANDLE, NULL
                        invoke SetDlgItemTextW, hDlg, ID_WNDPROC, NULL
                    .endif
                .endif
            .endif
        .endif
    .else
        mov eax, FALSE
        ret
    .endif
    mov eax, TRUE
    ret
DlgFunc endp

main:
    invoke GetModuleHandle,NULL
    mov hInstance,eax
    invoke DialogBoxParamW,hInstance,ID_MAINDLG,NULL,addr DlgFunc,NULL
    invoke ExitProcess,NULL
end main