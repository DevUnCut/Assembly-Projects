.586
.model flat,stdcall
option casemap:none
.stack 4096

include \masm32\include\windows.inc
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib


input       MACRO  inPrompt, inStr, maxLength     ; prompt for and input  string
	        pushad                     ; save general registers
            mov    ebx, maxLength      ; length of input string
            push   ebx                 ; length parameter on stack
            lea    ebx,inStr           ; destination address
            push   ebx                 ; dest parameter on stack
            lea    ebx,inPrompt        ; prompt address
            push   ebx                 ; prompt parameter on stack
            call   getInput           ; getInput(inPrompt, inStr, maxLength)
			add    esp, 12             ; remove parameters
            popad                      ; restore general registers
ENDM

.const
	IDC_TEXT	equ 1000
	IDD_MAIN	equ 1001
	IDC_OK		equ 1007
	IDC_EXIT	equ 1008
	IDC_LABEL	equ 1009
.data
	buf dword 255 dup (?)               ; to be used to temporarily hold user input

    DlgName byte "My Dialog", 0
	
    inputLabel BYTE 255 dup (?)
	inputPrompt BYTE "Enter in a string", 0
    
    inputTitle byte "The string that was entered is", 0
    userInputStr byte 40 dup (?)
	noInputLabel BYTE "Nothing entered", 0
	noInput		 BYTE "Warning", 0

    outputLabel byte "The modified string is", 0

	hDlg DWORD ? ; Variable to store the dialog box handle
    Msg MSG <>    ; Structure for message information


.data?
    hInst HINSTANCE ?
.code
DlgProc PROC
    ; DlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
	;LOCAL len:dword         ; we added another word onto stack so we'll be off by 4 bytes than the cdecl protocol

    PUSH EBP                ; save current address that is stored in ebp onto stack
    MOV EBP, ESP            ; establish stack framework
    push ecx                ; save general perpose registers
    MOV edx, [ebp + 8]      ; hDlg
    MOV ecx, [ebp + 12]     ; uMsg
    MOV ebx, [ebp + 16]     ; wParam
    MOV esi, [ebp + 20]     ; lParam

MessageLoop:
    ; Process messages
    CMP ecx, WM_INITDIALOG
    JE HandleInitDialog
    CMP ecx, WM_COMMAND
    JE HandleCommand
    CMP ecx, WM_CLOSE
    JE HandleClose
    ; Default message processing
    JMP DefaultHandler
    HandleInitDialog:
        ; Initialize the dialog box controls
        ; ...
        invoke SetDlgItemTextA, edx, IDC_LABEL, offset inputLabel
        invoke SetDlgItemTextA, edx, IDC_TEXT, " "
        JMP Done
    HandleCommand:
        ; Handle command messages from controls
        CMP EBX, IDC_OK ; Example: Check for OK button
        JE HandleOK
        ; ... other control ID checks ...
        cmp ebx, IDC_EXIT
        je HandleClose
        JMP Done

    HandleOK:
        ; When somebody clicks OK, get the number of characters entered
        ;int len = GetWindowTextLength(GetDlgItem(hwnd, IDC_TEXT))
        invoke GetDlgItem, edx, IDC_TEXT
        invoke GetWindowTextLength, eax
        ; after the invoke has been executed the edx and ecx register will have become effected
        ; get back the correct values for the hDlg and uMsg
        MOV edx, [ebp + 8]      ; hDlg
        MOV ecx, [ebp + 12]     ; uMsg

        cmp eax, 0
        jg GreaterThanZero
        invoke MessageBoxA, edx, offset noInputLabel, offset noInput, MB_OK
        jmp Done
        GreaterThanZero:
            ; get the string into our buffer and exit
            ; GetDlgItemText(hwnd, IDC_TEXT, buf, len + 1);
            inc eax
            invoke GetDlgItemTextA, edx, IDC_TEXT, offset buf, eax
            mov edx, [ebp + 8]
            invoke EndDialog, edx, 0
            JMP Done
    HandleClose:
        ; Close the dialog box
        mov edx, [ebp + 8]
        INVOKE EndDialog, EDX, 0
        JMP Done

    DefaultHandler:
        ; Default message handling
        ; Note: You'll need to push parameters in reverse order for DefWindowProc
        ; LRESULT DefWindowProcA(HWND   hWnd,UINT   Msg, WPARAM wParam, LPARAM lParam)
        PUSH esi 
        PUSH ebx
        PUSH ecx
        PUSH edx
        CALL DefWindowProc
        MOV EAX, FALSE
Done:
    pop ecx
    POP ebp
    RET
DlgProc endp


strcopy PROC NEAR32
; Procedure to copy string until null byte in source is copied.
; Destination location assumed to be long enough to hold copy.
; Parameters:
; (1) address of destination 
; (2) address of source
push ebp          ;save base pointer
mov ebp,esp       ;copy stack pointer

push edi          ;save registers
push esi          ;save registers
pushfd            ;save flags

mov edi,[ebp+8]    ;destination
mov esi,[ebp+12]   ;initial source address
cld               ;clear direction flag

whileNoNull:
  cmp BYTE PTR [esi],0  ;null source byte?
  je endWhileNoNull      ;stop copying if null
  movsb            ;copy one byte
  jmp whileNoNull  ;go check next byte

endWhileNoNull:
  mov BYTE PTR [edi],0  ;terminate destination string
  popfd           ;restore flags
  pop esi          ;restore registers
  pop edi          ;restore registers
  pop ebp          ;restore registers
  ret             ;return

strcopy ENDP

getInput PROC NEAR32
;   void getInput(char* inputPrompt, char* result, int maxChars)
;   // generate an input dialog with prompt as a label
;   // and a text box to input a string of up to maxChars characters,
;   // returned in result
;
;   Parameters:
;       (1) address of inputPrompt (char*)
;       (2) address of result (char*)
;       (3) maxChars (int)
    push ebp            ; save base pointer
    mov ebp, esp        ; copy stack pointer
    push edi            ; save registers
    push esi            ; save registers

    mov eax, [ebp + 8] ; inputPrompt
    mov edx, [ebp + 12] ; result
    mov ecx, [ebp + 16]  ; maxChars

    push eax
    lea ebx, inputLabel
    push ebx
    call strcopy
    add esp, 8

    ;invoke DialogBoxParamA, hInst, offset IDD_MAIN, NULL, offset DlgProc, NULL
    push NULL
    lea eax, DlgProc
    push eax
    push NULL
    push IDD_MAIN
    push hInst
    call DialogBoxParamA
    ; reload the maxChars into ecx register
    mov ecx, [ebp + 16]
    dec ecx
    mov buf[ecx], 0

    lea eax, buf
    push eax
    lea eax, userInputStr
    push eax
    call strcopy
    add esp, 8
    pop esi
    pop edi
    pop ebp
    ret
getInput ENDP


main PROC
    input   inputPrompt, userInputStr, 40      ; read ASCII characters
    invoke MessageBoxA, NULL, offset userInputStr, offset inputTitle, NULL
	
	; setup for code 1 
	lea esi, userInputStr			; load the source string into source index to be used with movsb instruction
	lea edi, userInputStr+1		; load the destination (string plus 1 byte offset) into destination index to be used with movsb instruction
	cld
    movsb
	movsb
	movsb
	movsb
    invoke MessageBoxA, NULL, offset userInputStr, offset outputLabel, NULL

    comment%
	; setup for code 2
	lea esi, userInputStr			; load the source string into source index to be used with movsb instruction
	lea edi, userInputStr+2		; load the destination (string plus 2 byte offset) to get 'C' into destination index to be used with movsb instruction
	cld
    movsb
    movsb
    movsb
    movsb
    invoke MessageBoxA, NULL, offset userInputStr, offset outputLabel, NULL


	; setup for code 3
	lea esi, userInputStr+9		; load the source string into source index to be used with movsb instruction -- this time we'll be using the end of the string
	lea edi, userInputStr+4		; load the destination (string plus 4 byte offset) to get 'E' into destination index to be used with movsb instruction
	std
    movsb
    movsb
    movsb
    movsb
    invoke MessageBoxA, NULL, offset userInputStr, offset outputLabel, NULL

	; setup for code 4
	lea esi, userInputStr+9
	lea edi, userInputStr+7
	std
    movsb
    movsb
    movsb
    movsb
	; now lets display our modified string
	invoke MessageBoxA, NULL, offset userInputStr, offset outputLabel, NULL
    %
	mov eax, 0
	ret
main ENDP
end