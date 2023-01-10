.386
.model flat,stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib

wWinMain proto :DWORD,:DWORD,:DWORD,:DWORD

.data
DialogClass word 'D','L','G','C','L','A','S','S',0
MenuName word 'M','y','M','e','n','u',0
MsgTitle word 'M','e','s','s','a','g','e',0
DialogBoxName word 'M','y','D','i','a','l','o','g',0
TestStr word 'W','o','w','!',' ','I','m',' ','i','n',0



.data?
hInstance HINSTANCE ?
CmdLine LPSTR ?
buffer word 512 dup(?)


.const
IDC_EDIT        equ 3000
IDC_BUTTON      equ 3001
IDC_EXIT        equ 3002

IDM_GETTEXT     equ 32000
IDM_CLEAR       equ 32001
IDM_EXIT        equ 32002

.code
    wWinMain PROC hInst:HINSTANCE, hPrevInst:HINSTANCE, cmdLine:PWSTR, cmdShow:dword
        LOCAL wc:WNDCLASSEXW ; create our window class variable
        LOCAL msg:MSG        ; create our variable to hold WM_?? window messages for us
        LOCAL hDlg:HWND      ; the handle to our dialog box !

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; In this program we're going to be using a dialog box as our main window ! !   ;
        ; PLEASE NOTE THAT setting up our dialog box as the main window is a super easy ;
        ; we've actually kinda already been doing a lot of the house keeping, we're     ;
        ; still going to have to do everything the same as if we were going to create   ;
        ; a window class that we are going to use,< but we're actually not going to >   ;
        ; INSTEAD WE ARE JUST GOING TO DO EVERYTHING WE'VE BEEN DOING EXCEPT            ;
        ; NO WINDOW CREATION ! ! ! Instead we are to call upon the CreateDialogParam()  ;
        ; that will create a modeless dialog box ! ! !                                  ;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        mov wc.cbSize, sizeof WNDCLASSEXW
        mov wc.style, CS_HREDRAW or CS_VREDRAW
        mov wc.lpfnWndProc, offset WndProc
        mov wc.cbClsExtra, NULL ; No, do not allocate extra bytes !

        ; this is where the magic happens at this next variable for us to use a dialog box as a main window
        mov wc.cbWndExtra, DLGWINDOWEXTRA ; this right here is what allows us to use the dialog box as main window
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; The number of extra bytes to allocate following the window instance. The system initializes the bytes to zero.        ;
        ; If an application uses WNDCLASSEX to register a dialog box created by using the CLASS directive in the resource file, ;
        ; it must set this member to DLGWINDOWEXTRA. < taken from win 32 api guide provided by microsoft ! >                    ;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        push hInst
        pop wc.hInstance

        invoke LoadIconW, NULL, IDI_APPLICATION
        mov wc.hIcon, eax
        mov wc.hIconSm, eax

        invoke LoadCursorW, NULL, IDC_ARROW
        mov wc.hCursor, eax

        mov wc.hbrBackground, COLOR_WINDOW+2
        mov wc.lpszMenuName, offset MenuName
        mov wc.lpszClassName, offset DialogClass
        
        ; all of the house keeping is done all there is to do now is to register the class and call upon the CreateDialogParam()
        invoke RegisterClassExW, addr wc
        invoke CreateDialogParamW,hInstance,ADDR DialogBoxName,NULL,NULL,NULL

        ; Now we've created our dialog box as a main window it's handle is returned in the eax register
        ; let us now put that address into our variable that is to hold the handle to our dialog box !
        mov hDlg,eax

        ; We're ready to display the window to our user now !
        ; so let us display our window onto the desktop
        invoke ShowWindow, hDlg,SW_SHOWNORMAL

        ; then refresh the client area !
        invoke UpdateWindow, hDlg

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ; since a Dialog box is defined as a resource much that our Menu is as well.;
        ; we can weite a dialog box template by describing the characteristics of   ;
        ; the dialog box along with it's controls !                                 ;
        ; ( We're going to be making it in a seperate resource file)                ;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        invoke GetDlgItem,hDlg,IDC_EDIT ; show the user the Edit Dialog Box, that belongs to the handle of our dialog box !
        invoke SetFocus,eax ; as soon as the window pop's up switch the input focus to that new window !

        ; message loop !
        .WHILE TRUE
            invoke GetMessageW, ADDR msg,NULL,0,0
            .BREAK .IF (!eax)
           invoke IsDialogMessageW, hDlg, ADDR msg
            .IF eax ==FALSE
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessageW, ADDR msg
            .ENDIF
        .ENDW
        mov eax,msg.wParam
        ret
    wWinMain endp

    WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
        .IF uMsg==WM_DESTROY
            invoke PostQuitMessage,NULL
        .ELSEIF uMsg==WM_COMMAND
            mov eax,wParam
            .IF lParam==0
                .IF ax==IDM_GETTEXT
                    invoke GetDlgItemTextW,hWnd,IDC_EDIT,ADDR buffer,512
                    invoke MessageBoxW,NULL,ADDR buffer,ADDR MsgTitle, MB_OK
                .ELSEIF ax==IDM_CLEAR
                    invoke SetDlgItemTextW,hWnd,IDC_EDIT,NULL
                .ELSE
                    invoke DestroyWindow,hWnd
                .ENDIF
            .ELSE
                mov edx,wParam
                shr edx,16
                .IF dx==BN_CLICKED
                    .IF ax==IDC_BUTTON
                        invoke SetDlgItemTextW,hWnd,IDC_EDIT,ADDR TestStr
                    .ELSEIF ax==IDC_EXIT
                        invoke SendMessageW,hWnd,WM_COMMAND,IDM_EXIT,0
                    .ENDIF
                .ENDIF
            .ENDIF
        .ELSE
            invoke DefWindowProcW,hWnd,uMsg,wParam,lParam
            ret
        .ENDIF
        xor    eax,eax
        ret
    WndProc endp

    main:
        invoke GetModuleHandle, NULL
        mov    hInstance,eax
        invoke GetCommandLine
        mov CmdLine,eax
        invoke wWinMain, hInstance,NULL,CmdLine, SW_SHOWDEFAULT
        invoke ExitProcess,eax
    end main