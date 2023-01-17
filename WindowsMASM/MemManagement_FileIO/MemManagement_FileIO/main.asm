.386
.model flat,stdcall
option casemap:none

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

WIDE MACRO varname:REQ, string:REQ, args:VARARG
    @CatStr(<&varname& WORD >, !', @SubStr(<&string&>, 2, 1), !')

    % FORC chr, <@SubStr(<&string&>, 3, @SizeStr(<&string&>)-3)>
        WORD '&chr&'
    ENDM

    FOR arg, <&args&>
        WORD &arg&
    ENDM

ENDM

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\comdlg32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\comdlg32.lib

.const
IDM_OPEN equ 1
IDM_SAVE equ 2
IDM_EXIT equ 3

MAXSIZE equ 260
MEMSIZE equ 65535

EditID equ 1 ;ID of the edit control

.data
WIDE ErrorMsg, "unable to open file successfully, try again" ,0
WIDE ClassName, "EditClass", 0
WIDE AppName, "Edit Box", 0
WIDE EditClass, "edit", 0
WIDE MenuName, "MyMenu", 0

ofn   OPENFILENAMEW <>
open_file word 'c','a','n','n','o','t', 'O','p','e','n', 0

FilterString word 'A','l','l',' ','F','i','l','e','s',0,'*','.','*',0
             word 'T','e','x','t',' ','F','i','l','e','s',0,'*','.','t','x','t',0,0

buffer word MAXSIZE dup(0) ; the variable where we are going to temporarily store data

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?
hWndEdit HWND ? ; handle to our edit window

hFile HANDLE ? ; this variable will contain our handle to the selected file !
hMemory HANDLE ? ; handle to our requested allocated memory block
pMemory DWORD ? ; pointer to the allocated memory block
SizeReadWrite DWORD ? ; number of bytes we're actually going to be reading or writing !

.code

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
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
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .if uMsg == WM_DESTROY
        invoke PostQuitMessage, NULL
    .elseif uMsg == WM_CREATE
        invoke CreateWindowExW, NULL, addr EditClass, NULL,
            WS_VISIBLE or WS_CHILD or ES_LEFT or ES_MULTILINE or\
                   ES_AUTOHSCROLL or ES_AUTOVSCROLL,0,
                   0 , 0, 0, hWnd, EditID,
                   hInstance, NULL  ; this function call creates our edit window
        mov hWndEdit, eax
        invoke SetFocus, hWndEdit

        ;===================================================
        ; Initialize the members of OPENFILENAME structure =
        ;===================================================

        mov ofn.lStructSize,SIZEOF ofn

        push hWnd
        pop  ofn.hWndOwner

        push hInstance
        pop  ofn.hInstance

        mov  ofn.lpstrFilter, OFFSET FilterString
        mov  ofn.lpstrFile, OFFSET buffer ; so our buffer variable and our OPENFILENAMEW lpstrFile member are the same !
        mov  ofn.nMaxFile,MAXSIZE
    .ELSEIF uMsg==WM_SIZE
        mov eax,lParam
        mov edx,eax
        shr edx,16
        and eax,0ffffh
        invoke MoveWindow,hWndEdit,0,0,eax,edx,TRUE

    .ELSEIF uMsg==WM_COMMAND
        mov eax,wParam
        .if lParam==0
            .if ax==IDM_OPEN
                mov  ofn.Flags, OFN_FILEMUSTEXIST or \
                                OFN_PATHMUSTEXIST or OFN_LONGNAMES or\
                                OFN_EXPLORER or OFN_HIDEREADONLY
                invoke GetOpenFileNameW, ADDR ofn ; display the open file dialog box to our user !
                .if eax == TRUE ; we've successfully selected a file
                    ; since ofn.lpstrFile is the same as buffer variable i thought using the data member
                    ; would be a better approach but it seems as if that won't work so lets just
                    ; continue to use the buffer variable !
                    ; =========================
                    ; after displaying both variable to the screen with the MessageBox function
                    ; it turns our that the data member for the openfilename is just a pointer .... memory location
                    ; so it seems like its a bunch of garbage, but however our buffer variable has the file path location
                    ; of the file we'd like to open, which is what is required for that first argument in the function call !
                    ;==========================
                    invoke CreateFileW, ADDR buffer,
                                GENERIC_READ or GENERIC_WRITE ,\
                                FILE_SHARE_READ or FILE_SHARE_WRITE,\
                                NULL,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,\
                                NULL
                    ; now don't forget to store the handle to our file in our variable that we've prepared for it !
                    mov hFile, eax

                    ; we're set for the main event ... lets display the text that contained within that file that
                    ; we've just got the handle to ! !
                    ; now that we've opened the file we'll still need to allocate a block of memory so that
                    ; it can be used by the ReadFile, or WriteFile functions !
                    ; specifically we need to specify the GMEM_MOVABLE flag, to let windows know that it is
                    ; ok for it to move that memory block around, this is done to consolidate memory ! !
                    invoke GlobalAlloc, GMEM_MOVEABLE or GMEM_ZEROINIT, MEMSIZE
                    mov hMemory, eax ; store the handle to the memory block !

                    ; locking the memory is critical because this function returns back a pointer to the
                    ; memory block, which is used by the ReadFile and WriteFile functions !
                    invoke GlobalLock, hMemory
                    mov pMemory, eax ; store the pointer to memory block

                    invoke ReadFile,hFile,pMemory,MEMSIZE-1,ADDR SizeReadWrite,NULL
                    invoke SendMessage,hWndEdit,WM_SETTEXT,NULL,pMemory ; send our Edit control window a WM_SETTEXT
                                                                        ; message so that it displays the data
                                                                        ; that we've just read in that is being pointed
                                                                        ; to by our pMemory address ! !
                    ; close file and give our user an option if they'd like
                    ; to save to a new file or overwrite the current file
                    ; that code will be written in the IDM_SAVE section of the if else statements !
                    invoke CloseHandle,hFile
                    invoke GlobalUnlock,pMemory
                    invoke GlobalFree,hMemory
                .else ; we did not select a file ! 
                    invoke MessageBoxW, hWnd, offset open_file, 0, 0
                .endif
                ; don't forget to reset the input focus back to our Edit control window
                ; remember we've moved the focus to our open file dialog window, so we must set it
                ; back to our Edit control window ! !
                invoke SetFocus,hWndEdit
            .elseif ax == IDM_SAVE
                ; we must prep the OPENFILENAME structure before we display our Save As dialog box !
                 mov ofn.Flags,OFN_LONGNAMES or\
                    OFN_EXPLORER or OFN_HIDEREADONLY or OFN_CREATEPROMPT or\
                    OFN_OVERWRITEPROMPT
                invoke GetSaveFileNameW, ADDR ofn ; show our user the Save As Dialog box !
                
                .if eax == TRUE ; the user has selected where to save the file, along with the option
                                ; of if the would like to overwrite the current file !
                    ; we can actually just rinse and repeat the exact same steps from IDM_OPEN section !
                    ; if we choose an existing file and would like to overwrite the original we must
                    ; choose OPEN_EXISTING for the dwCreationDisposition parameter in the CreateFileW function call !
                    invoke CreateFileW,ADDR buffer,
                        GENERIC_READ or GENERIC_WRITE ,
                        FILE_SHARE_READ or FILE_SHARE_WRITE,
                        NULL, CREATE_NEW or OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, NULL
                    mov hFile,eax

                    invoke GlobalAlloc,GMEM_MOVEABLE or GMEM_ZEROINIT,MEMSIZE
                    mov  hMemory,eax

                    invoke GlobalLock,hMemory
                    mov  pMemory,eax

                    invoke SendMessage,hWndEdit,WM_GETTEXT,MEMSIZE-1,pMemory
                    invoke WriteFile,hFile,pMemory,eax,ADDR SizeReadWrite,NULL
                    invoke CloseHandle,hFile
                    invoke GlobalUnlock,pMemory
                    invoke GlobalFree,hMemory
                    ;invoke MessageBoxW, hWnd, offset open_file, 0, 0
                .endif
                invoke SetFocus,hWndEdit
            .elseif ax == IDM_EXIT
                invoke ExitProcess, 0
            .else
                invoke DestroyWindow, hWnd
            .endif
        .endif
    .else
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
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax

end main