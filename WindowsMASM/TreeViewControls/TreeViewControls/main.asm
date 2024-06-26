.386
.model flat,stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\comctl32.inc
include \masm32\include\gdi32.inc

includelib \masm32\lib\gdi32.lib
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

WinMain PROTO :DWORD, :DWORD, :DWORD, :DWORD

.const
ID_TREE equ 4006	; The ID to the bitmap resource we'll be using

.data
WIDE ClassName, "TreeViewWinClass", 0
WIDE WindowName, "Tree View Control Window Demo", 0
WIDE TreeViewClass, "SysTreeView32", 0

;WIDE Parent, "Parent", 0
Parent word 4e93h, 6c17h, 3067h, 3059h, 0 ; genki desu
WIDE Child1, "This item is a child to the parent item", 0
WIDE Child2, "Child2 object is a child to the parent item", 0

DragMode dd FALSE   ; this flag will be used to determined the use of drag
                    ; and drop mode for the Tree View Control Window

.data?
hInstance       HINSTANCE ?
hwndTreeView    dd ? ; handle to the Tree View Control Window
hParent         dd ? ; handle to the parent item in the Tree View Control
                     ; this handle is typically to the root of the tree view item

hImageList      dd ? ; handle to the image list that we'll be using
                     ; before we set the handle we must first create the
                     ; image list and once created we must insert images into
                     ; the list

hDragImageList  dd ? ; handle to the image list to use when Drag and Drop mode
                     ; is enabled if not enabled then set to NULL

.code
wWinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
; lets set up the variables we need for our window !
    LOCAL wc:WNDCLASSEXW
    LOCAL msg:MSG
    LOCAL hwnd:HWND

    mov   wc.cbSize,SIZEOF WNDCLASSEXW
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL

    push  hInstance
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
    invoke CreateWindowExW, WS_EX_CLIENTEDGE,ADDR ClassName,ADDR WindowName,
                            WS_OVERLAPPED+WS_CAPTION+WS_SYSMENU+WS_MINIMIZEBOX+WS_MAXIMIZEBOX+WS_VISIBLE,CW_USEDEFAULT,
                            CW_USEDEFAULT,200,400,NULL,NULL,
                            hInst,NULL
    mov   hwnd,eax
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

; here in our WndProc function definition is a little bit different than
; what we're used to we'll be using the uses edi directive for the funct call !
; the entire WndProc uses different messages to communicated to the
; Tree View Control Window which we'll set up right now !
WndProc proc uses edi hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL TreeViewInsert:TV_INSERTSTRUCT
    LOCAL hBitmap:DWORD
    LOCAL TreeViewHit:TV_HITTESTINFO
    ; the above local variables are what we'll need to interact with
    ; the tree view control window !
    .if uMsg == WM_CREATE
        invoke CreateWindowExW,NULL,ADDR TreeViewClass,NULL,
            WS_CHILD+WS_VISIBLE+TVS_HASLINES+TVS_HASBUTTONS+TVS_LINESATROOT,0,
            0,200,400,hWnd,NULL,
            hInstance,NULL            ; Create the tree view control
        ; now we can store the handle that is returned in the eax register !
        mov hwndTreeView,eax

        ; Lets start off by creating the Image List so we can load
        ; images we would like to use when displaying the parent and child items
        invoke ImageList_Create, 16, 16, ILC_COLOR16,2,10
        mov hImageList, eax

        ; now we ready to load to load any bitmaps that we'll be using
        invoke LoadBitmapW, hInstance,ID_TREE ; load the bitmap from the resource
        mov hBitmap, eax

        ; Now that the setup is finished we're ready to start storing
        ; images into the Image List ! !
        ; Lets start off by adding in the bitmap into the image list
        invoke ImageList_Add, hImageList, hBitmap, NULL
        ; ALWAYS DELETE A BITMAP RESOURCE FROM ONCE ADDED INTO IMAGE LIST !
        invoke DeleteObject, hBitmap

        ; NOW LETS MAKE USE OF WINDOWS MESSAGES AND COMMUNICATE
        ; WITH THE TREE VIEW CONTROL WINDOW VIA MESSAGES ! !
        invoke SendMessageW, hwndTreeView, TVM_SETIMAGELIST, 0, hImageList

        mov TreeViewInsert.hParent,             NULL
        mov TreeViewInsert.hInsertAfter,        TVI_ROOT
        mov TreeViewInsert.item.imask,          TVIF_TEXT+TVIF_IMAGE+TVIF_SELECTEDIMAGE
        mov TreeViewInsert.item.pszText,        offset Parent
        mov TreeViewInsert.item.iImage,         0
        mov TreeViewInsert.item.iSelectedImage, 1

        ; I WAS RUNNING INTO A "BUG" WHERE THE TREE VIEW CONTROL WILL NOT
        ; PROPERLY HANDLE UNICODE CHARACTERS ... IM TRYING TO DISPLAY
        ; JAPANESE CHARACTERS WITHIN THE  APPLICATION'S TREE VIEW CONTROL
        ;
        ; ... I CALLED THIS A "BUG" BECUASE IT'LL RUN WITHOUT CRASHING BUT
        ; IT'LL ONLY DISPLAY A SINGLE CHARACTER THEN THE REST WAS JUNK 
        ; (NULL TERMINATED STRING)
        ;
        ; IN THE WINDOWS API CALLING CONVENTION METHODS AND OR MACROS HAVE
        ; ASCII AND UNICODE VERSIONS OF EACH METHOD TO HANDLE ITS RESPECTIVE
        ; DATA TYPE. I WAS CALLING: TVM_INSERTITEM
        ; and windows defaults to system defaults so being in NA it defaults to
        ; ASCII so TO GET THE PROPER FUNCTIONALITY ALL WE HAVE TO DO IS USE
        ; THE UNICODE VERSION OF THE TVM_INSERTITEM METHOD SO LET US CALL
        ;               TVM_INSERTITEMW
        ;
        
        invoke SendMessageW, hwndTreeView, TVM_INSERTITEMW, 0, addr TreeViewInsert
        mov hParent, eax
        mov TreeViewInsert.hParent, eax
        mov TreeViewInsert.hInsertAfter, TVI_LAST
        mov TreeViewInsert.item.pszText, offset Child1

        invoke SendMessageW, hwndTreeView, TVM_INSERTITEMW, 0, addr TreeViewInsert
        mov TreeViewInsert.item.pszText, offset Child2

        invoke SendMessageW, hwndTreeView, TVM_INSERTITEMW, 0, addr TreeViewInsert
    .elseif uMsg == WM_MOUSEMOVE
            .if DragMode==TRUE
                mov eax,lParam
                and eax,0ffffh
                mov ecx,lParam
                shr ecx,16
                mov TreeViewHit.pt.x,eax
                mov TreeViewHit.pt.y,ecx
                invoke ImageList_DragMove,eax,ecx
                invoke ImageList_DragShowNolock,FALSE
                invoke SendMessageW,hwndTreeView,TVM_HITTEST,NULL,addr TreeViewHit
                .if eax!=NULL
                    invoke SendMessageW,hwndTreeView,TVM_SELECTITEM,TVGN_DROPHILITE,eax
                .endif
                invoke ImageList_DragShowNolock,TRUE
            .endif
    .elseif uMsg == WM_LBUTTONUP
        .if DragMode == TRUE
            invoke ImageList_DragLeave,hwndTreeView
            invoke ImageList_EndDrag
            invoke ImageList_Destroy,hDragImageList
            invoke SendMessageW,hwndTreeView,TVM_GETNEXTITEM,TVGN_DROPHILITE,0
            invoke SendMessageW,hwndTreeView,TVM_SELECTITEM,TVGN_CARET,eax
            invoke SendMessageW,hwndTreeView,TVM_SELECTITEM,TVGN_DROPHILITE,0
            invoke ReleaseCapture
            mov DragMode,FALSE
        .endif
    .elseif uMsg == WM_NOTIFY
        mov edi, lParam
        assume edi:ptr NM_TREEVIEW
        .if [edi].hdr.code == TVN_BEGINDRAG
            invoke SendMessageW, hwndTreeView, TVM_CREATEDRAGIMAGE,0,[edi].itemNew.hItem
            mov hDragImageList, eax

            invoke ImageList_BeginDrag, hDragImageList, 0, 0, 0
            invoke ImageList_DragEnter, hwndTreeView, [edi].ptDrag.x, [edi].ptDrag.y
            invoke SetCapture, hWnd
            mov DragMode, TRUE
        .endif
        assume edi:nothing
    .elseif uMsg == WM_DESTROY
        invoke PostQuitMessage, NULL
    .else
        invoke DefWindowProcW, hWnd, uMsg, wParam, lParam
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