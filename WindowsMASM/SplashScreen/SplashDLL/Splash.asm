; This is the implementation file
; for our custom DLL which
; we'll use solely to display the bitmap
; for some time (a splash screen)
;
; WE'LL BE HANDLING THE WINDOWS MESSAGES
; SO THAT WE CAN CREATE A SPLASH SCREEN
.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
include \masm32\include\gdi32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\gdi32.lib

.data
BitmapName		word 'M','y','B','M','P',0
ClassName		word 'S','p','l','a','s','h','W','n','d','C','l','a','s','s',0

hBitmapFile		dd 0
TimerID			dd 0

.data?
hInstance		dd ?

.code
DllEntry proc hInst:DWORD, reason:DWORD, reserved1:DWORD
	.if reason == DLL_PROCESS_ATTACH ; THIS MEANS THAT THE DLL IS ALREADY LOADED
		push hInst
		pop hInstance

		call ShowBitmap ; show the user the image within the bitmap .bmp file
						; This is a call to our custom function 
						; that'll do the heavy lifing for us

	.endif
	mov eax, TRUE
	ret
DllEntry Endp

; The following proceedure/function/method
; is our custom function that'll be used to
; register a window class, create a window and 
; enter in a message loop as usual.
; 
; The interesting part is in the CreateWindowExW call:

ShowBitmap proc
; The below code is the same boiler plate code we are used to
; except we'll be choosing a differnt style for the window style
	LOCAL wc:WNDCLASSEX
	LOCAL msg:MSG
	LOCAL hwnd:HWND

	mov wc.cbSize, SIZEOF WNDCLASSEX
	mov wc.style, CS_HREDRAW or CS_VREDRAW
	mov wc.lpfnWndProc, OFFSET WndProc
	mov wc.cbClsExtra, NULL
	mov wc.cbWndExtra, NULL

	push hInstance
	pop wc.hInstance
	mov wc.hbrBackground, COLOR_WINDOW+1
	mov wc.lpszMenuName, NULL
	mov wc.lpszClassName, OFFSET ClassName

	invoke LoadIconW, NULL, IDI_APPLICATION
	mov wc.hIcon, eax
	mov wc.hIconSm, 0

	invoke LoadCursorW, NULL, IDC_ARROW
	mov wc.hCursor, eax

	invoke RegisterClassExW, addr wc
	; Here after we register the class in the CreateWindowExW call
	; we're going to be choosing a pop up window as the window style
	invoke CreateWindowExW, NULL, addr ClassName, NULL, WS_POPUP,
				CW_USEDEFAULT, CW_USEDEFAULT,
				250, 250,
				NULL, NULL,
				hInstance, NULL
	mov hwnd, eax
	invoke ShowWindow, hwnd, SW_SHOWNORMAL
	.while TRUE
		invoke GetMessageW, addr msg, NULL, 0, 0
		.break .if (!eax)
		invoke TranslateMessage, addr msg
		invoke DispatchMessage, addr msg
	.endw
	mov eax, msg.wParam
	ret
ShowBitmap endp

WndProc proc hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
; recall the CircleGFX windows api cpp program we did years ago it's a similar setup
; where we have to setup our paint structure.
	LOCAL ps:PAINTSTRUCT
	LOCAL hdc:HDC
	LOCAL hMemDC:HDC
	LOCAL hOldBMP:DWORD
	LOCAL Bitmap:BITMAP

	LOCAL DlgHeight:DWORD
	LOCAL DlgWidth:DWORD
	LOCAL DlgRect:RECT
	LOCAL DesktopRect:RECT

	.if uMsg == WM_DESTROY
		.if hBitmapFile != 0 ; we have a active bitmap
			invoke DeleteObject, hBitmapFile
		.endif
		invoke PostQuitMessage, NULL
	.elseif uMsg == WM_CREATE
		; lets get the rectangle structure ready for painting
		invoke GetWindowRect, hWnd, addr DlgRect
		invoke GetDesktopWindow
		mov ecx, eax

		invoke GetWindowRect, ecx, addr DesktopRect
		push 0
		mov eax, DlgRect.bottom
		sub eax, DlgRect.top
		mov DlgHeight, eax

		push eax
		mov eax, DlgRect.right
		sub eax, DlgRect.left
		mov DlgWidth, eax

		push eax
		mov eax, DesktopRect.bottom
		sub eax, DlgHeight
		shr eax, 1

		push eax
		mov eax, DesktopRect.right
		sub eax, DlgWidth
		shr eax, 1

		push eax
		push hWnd

		call MoveWindow
		invoke LoadBitmapW, hInstance, addr BitmapName
		mov hBitmapFile, eax

		invoke SetTimer, hWnd, 1, 2000, NULL
		mov TimerID, eax
	.elseif uMsg == WM_TIMER
		invoke SendMessageW, hWnd, WM_LBUTTONDOWN, NULL, NULL
		invoke KillTimer, hWnd, TimerID
	.elseif uMsg == WM_PAINT
		; again let us recall the CircleGFX windows api cpp program we did years ago it's a similar setup
		; Where now we have call the BeginPaint function but here is assembly language its a bit differnt not entirely though
		invoke BeginPaint, hWnd, addr ps ; let us begin the paint procedures along with passing our paint structure that we'll use for all the painting
		mov hdc, eax

		invoke CreateCompatibleDC, hdc
		mov hMemDC, eax

		invoke SelectObject, eax, hBitmapFile
		mov hOldBMP, eax

		invoke GetObject, hBitmapFile, sizeof BITMAP, addr Bitmap
		invoke StretchBlt, hdc, 0, 0, 250, 250,
						hMemDC, 0, 0, Bitmap.bmWidth, Bitmap.bmHeight, SRCCOPY
		invoke SelectObject, hMemDC, hOldBMP
		invoke DeleteDC, hMemDC
		invoke EndPaint, hWnd, addr ps
	.elseif uMsg == WM_LBUTTONDOWN
		invoke DestroyWindow, hWnd
	.else
		invoke DefWindowProcW, hWnd, uMsg, wParam, lParam
		ret
	.endif
	xor eax, eax
	ret
WndProc endp
End DllEntry