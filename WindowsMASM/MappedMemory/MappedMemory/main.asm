.386
.model flat, stdcall
option casemap:none

include \masm32\include\kernel32.inc
include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\comdlg32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\comdlg32.lib
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
IDM_OPEN equ 2
IDM_SAVE equ 3
IDM_EXIT equ 4

MAXSIZE equ 260

.data
WIDE AppName, "My First App", 0
WIDE ClassName, "Memory Mapped File Class", 0
WIDE MenuName, "MyMenu",0

ofn   OPENFILENAMEW <>
FilterString word 'A','l','l',' ','F','i','l','e','s',0,'*','.','*',0
             word 'T','e','x','t',' ','F','i','l','e','s',0,'*','.','t','x','t',0,0
buffer word MAXSIZE dup(0)
hMapFile HANDLE 0                            ; Handle to the memory mapped file, must be
                                             ;initialized with 0 because we also use it as

WIDE TestStr, "A wide unicode string", 0

.data?
hInstance HINSTANCE ?
CommandLine LPSTR ?
hFileRead HANDLE ?                               ; Handle to the source file
hFileWrite HANDLE ?                                ; Handle to the output file
hMenu HANDLE ?
pMemory DWORD ?                                 ; pointer to the data in the source file
SizeWritten DWORD ?                               ; number of bytes actually written by WriteFile

.code


WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
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
    mov   wc.lpszMenuName,OFFSET MenuName
    mov   wc.lpszClassName,OFFSET ClassName

    invoke LoadIconW,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax

    invoke LoadCursorW,NULL,IDC_ARROW
    mov   wc.hCursor,eax

    invoke RegisterClassExW, addr wc
    invoke CreateWindowExW,WS_EX_CLIENTEDGE,ADDR ClassName,\
                ADDR AppName, WS_OVERLAPPEDWINDOW,CW_USEDEFAULT,\
               CW_USEDEFAULT,300,200,NULL,NULL, hInst,NULL
    mov   hwnd,eax

    invoke ShowWindow, hwnd,SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    .WHILE TRUE
        invoke GetMessageW, ADDR msg,NULL,0,0
        .BREAK .IF (!eax)
        invoke TranslateMessage, ADDR msg
        invoke DispatchMessage, ADDR msg
    .ENDW
    mov     eax,msg.wParam
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    .IF uMsg == WM_CREATE
        invoke GetMenu,hWnd                       ;Obtain the menu handle
        mov  hMenu,eax

        mov ofn.lStructSize,SIZEOF ofn
        push hWnd
        pop  ofn.hWndOwner
        push hInstance
        pop  ofn.hInstance
        mov  ofn.lpstrFilter, OFFSET FilterString
        mov  ofn.lpstrFile, OFFSET buffer
        mov  ofn.nMaxFile,MAXSIZE

    .ELSEIF uMsg == WM_DESTROY
        .if hMapFile!=0
            call CloseMapFile
        .endif
        invoke PostQuitMessage,NULL
    .ELSEIF uMsg == WM_COMMAND
        mov eax,wParam
        .if lParam == 0
            .if ax == IDM_EXIT
                invoke PostQuitMessage, 0
            .elseif ax==IDM_OPEN
                mov  ofn.Flags, OFN_FILEMUSTEXIST or \
                                OFN_PATHMUSTEXIST or OFN_LONGNAMES or\
                                OFN_EXPLORER or OFN_HIDEREADONLY
                invoke GetOpenFileNameW, ADDR ofn
                .if eax==TRUE
                    invoke CreateFileW,ADDR buffer,\
                                                GENERIC_READ ,\
                                                0,\
                                                NULL,OPEN_EXISTING,FILE_ATTRIBUTE_ARCHIVE,\
                                                NULL
                    mov hFileRead,eax

                    invoke CreateFileMappingW,hFileRead,NULL,PAGE_READONLY,0,0,NULL
                    mov     hMapFile,eax
                    mov     eax,OFFSET buffer
                    mov     dx,ofn.nFileOffset
                    L1:
                        add eax, 2
                        dec dx
                        cmp dx, 0
                        jne L1
                    invoke SetWindowTextW,hWnd,eax
                    invoke EnableMenuItem,hMenu,IDM_OPEN,MF_GRAYED
                    invoke EnableMenuItem,hMenu,IDM_SAVE,MF_ENABLED
                .endif
            .elseif ax==IDM_SAVE
                mov ofn.Flags,OFN_LONGNAMES or\
                                OFN_EXPLORER or OFN_HIDEREADONLY
                invoke GetSaveFileNameW, ADDR ofn
                .if eax==TRUE
                    invoke CreateFileW,ADDR buffer,\
                                                GENERIC_READ or GENERIC_WRITE ,\
                                                FILE_SHARE_READ or FILE_SHARE_WRITE,\
                                                NULL,CREATE_NEW,FILE_ATTRIBUTE_ARCHIVE,\
                                                NULL
                    mov hFileWrite,eax

                    invoke MapViewOfFile,hMapFile,FILE_MAP_READ,0,0,0
                    mov pMemory,eax

                    invoke GetFileSize,hFileRead,NULL
                    invoke WriteFile,hFileWrite,pMemory,eax,ADDR SizeWritten,NULL
                    invoke UnmapViewOfFile,pMemory

                    call   CloseMapFile

                    invoke CloseHandle,hFileWrite
                    invoke SetWindowTextW,hWnd,ADDR AppName
                    invoke EnableMenuItem,hMenu,IDM_OPEN,MF_ENABLED
                    invoke EnableMenuItem,hMenu,IDM_SAVE,MF_GRAYED
                .endif
            .else
                invoke DestroyWindow, hWnd
            .endif
        .endif
    .ELSE
        invoke DefWindowProcW, hWnd, uMsg, wParam, lParam
        ret
    .ENDIF
        xor eax,eax
        ret
WndProc endp

CloseMapFile PROC
        invoke CloseHandle,hMapFile
        mov    hMapFile,0
        invoke CloseHandle,hFileRead
        ret
CloseMapFile endp

main:
    invoke GetModuleHandle, NULL
    mov    hInstance,eax
    invoke GetCommandLine
    mov CommandLine,eax
    invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT
    invoke ExitProcess,eax
end main