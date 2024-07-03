; this is the DLL_Hook implementation file
.386
.model flat, stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc

includelib \masm32\lib\kernel32.lib
includelib \masm32\lib\user32.lib

.const
WM_MOUSEHOOK equ WM_USER+6

.data
hInstance	dd 0

.data?
hHook dd	?
hWnd dd		?

.code

DllEntry proc hInst:HINSTANCE, reason:DWORD, reserved1:DWORD
	.if reason == DLL_PROCESS_ATTACH
		push hInst
		pop hInstance
	.endif
	mov eax, TRUE
	ret
DllEntry endp

MouseProc proc nCode:DWORD, wParam:DWORD, lParam:DWORD
	invoke CallNextHookEx, hHook, nCode, wParam, lParam
	mov edx, lParam
	assume edx:PTR MOUSEHOOKSTRUCT

	invoke WindowFromPoint, [edx].pt.x, [edx].pt.y
	invoke PostMessageW, hWnd, WM_MOUSEHOOK, eax, 0
	assume edx:nothing

	xor eax, eax
	ret
MouseProc endp

InstallHook proc hwnd:DWORD
	push hwnd
	pop hWnd

	invoke SetWindowsHookExW, WH_MOUSE, addr MouseProc, hInstance, NULL
	mov hHook, eax
	ret
InstallHook endp

UninstallHook proc
	invoke UnhookWindowsHookEx, hHook
	ret
UninstallHook endp
End DllEntry