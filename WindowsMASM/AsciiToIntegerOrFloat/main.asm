.586
.model flat, stdcall
option casemap:none

.stack 4096

include /masm32/include/windows.inc
include /masm32/include/user32.inc
include /masm32/include/kernel32.inc

includelib /masm32/lib/user32.lib
includelib /masm32/lib/kernel32.lib

input       MACRO  inPrompt, inStr, maxLength		; prompt for and input  string
	        pushad									; save general registers
            mov    ebx, maxLength					; length of input string
            push   ebx								; length parameter on stack
            lea    ebx,inStr						; destination address
            push   ebx								; dest parameter on stack
            lea    ebx,inPrompt						; prompt address
            push   ebx								; prompt parameter on stack
            call   getInput							; getInput(inPrompt, inStr, maxLength)
			add    esp, 12							; remove parameters
            popad									; restore general registers
ENDM

.const
	IDC_TEXT	equ 1000
	IDD_MAIN	equ 1001
	IDC_OK		equ 1007
	IDC_EXIT	equ 1008
	IDC_LABEL	equ 1009
.data
	buf                 dword 255 dup (?)               ; to be used to temporarily hold user input
    userInputStr        byte 40 dup (?)
    inputLabel          BYTE 255 dup (?)

    DlgName             byte "My Dialog", 0
    

	inputPrompt         BYTE "Enter in a set of whole numbers or decimal numbers", 0
    inputTitle          BYTE "The string that was entered is", 0
    

    noInputTitle        BYTE "Warning", 0
	noInput             BYTE "Nothing entered", 0

    overFlowMsg         byte "Error overflow has occured in input please try smaller values !", 0
    iConverMsg          byte ".... Converting ASCII values into Integers !", 0
	fConverMsg          byte ".... Converting ASCII values into Floats/real floating point !", 0

    invalFloat          byte "The Float (decimal) value entered in is invalid !", 0
    invalType           byte "Cannot have a integer and deciaml number, please try again !", 0
    invalDigit          byte "an invalid digit was entered !", 0
    invalMsg            byte "Cannot insert the input into array !", 0
    outputLabel         byte "The modified string is", 0


    goodInput           byte "A valid input of either all integers or all floats was recieved !", 0
    goodTitle           byte "Horray !", 0
    myWordArr           word 150 dup (?)
    myREAL4Arr          REAL4 150 dup (?)
    flo                 REAL4 15.2          ; used for sanity check is 15.2 single precision floating point representation really 15.19999980926513671875
                                            ; which should gives us a hexadecimal value of 0x41733333 ... view this variable in memory debugger to confirm
                                            ; rounding error caused by indefinite repeating bit when converting the right side of the decimal portion
.data?

	hDlg DWORD ?        ; Variable to store the dialog box handle
    Msg MSG <>          ; Structure for message information
	hInst HINSTANCE ?   ; handle to window instance
.code

; atowproc(source) --- ascii to word 
; scan the source address, interpreting 
; ASCII characters as an word-size integer value which is returned in AX.

; Leading blanks are skipped.  A leading - or + sign is acceptable.
; Digit(s) must immediately follow the sign (if any).
; Memory scan is terminated by any non-digit.

; No error checking is done. If the number is outside the range for a
; signed word, then the return value is undefined.
atowproc    PROC
            push    ebp                 ; save base pointer
            mov     ebp, esp            ; establish stack frame
            sub     esp, 2              ; local space for sign
            push    ebx                 ; Save registers
            push    edx
            push    esi
            pushfd                      ; save flags

            mov     esi,[ebp+8]         ; get parameter (source addr)

; case if user enter's in number with a leading space
WhileBlankW:cmp    BYTE PTR [esi],' '  ; space?
            jne    EndWhileBlankW      ; exit if not
            inc    esi                 ; increment character pointer
            jmp    WhileBlankW         ; and try again
EndWhileBlankW:

; let us begin by storing the sign of the value to ax
            mov    ax,1                ; default sign multiplier (positive number)
IfPlusW:    cmp    BYTE PTR [esi],'+'  ; leading + ?
            je     SkipSignW           ; if so, skip over
IfMinusW:   cmp    BYTE PTR [esi],'-'  ; leading - ?
            jne    EndIfSignW          ; if not, save default +
            mov    ax,-1               ; -1 for minus sign
SkipSignW:  inc    esi                 ; move past sign
EndIfSignW:
            mov    [ebp-2],ax          ; save sign multiplier
            mov    ax,0                ; number being accumulated

; now we can compare the current ascii value to match either a integer or a float ! !

    WhileDigitW:cmp    BYTE PTR [esi], '-'
                je     IfMinusW
                cmp    BYTE PTR [esi],'0'  ; next character >= '0'
                jnge   EndWhileDigitW      ; exit if not
                cmp    BYTE PTR [esi],'9'  ; next character <= '9'
                jnle   EndWhileDigitW      ; not a digit if bigger than '9'
                cmp    BYTE PTR [esi], ' ' ; this is the end of the number in our dilimited string of ints/floats
                je     EndWhileDigitW
                cmp    BYTE PTR [esi],'.'  ; this lets us know that we are dealing with a float
                                           ; this conversion works up to the decimal point
                                           ; we now need to convert the right side of the decimal !
                je     EndWhileDigitW
                imul   ax,10               ; multiply old number by 10
                mov    bl,[esi]            ; ASCII character to BL
                and    bx,000Fh            ; convert to single-digit integer
                add    ax,bx               ; add to sum
                inc    esi                 ; increment character pointer
                jmp    WhileDigitW         ; go try next character

    EndWhileDigitW:

    ; if value is < 8000h, multiply by sign
                cmp    ax,8000h            ; 8000h?
                jnb    endIfMaxW           ; skip if not
                imul   WORD PTR [ebp-2]    ; make signed number
                cmp    BYTE PTR [esi], '.'
                je    endIfMaxW
                ;mov    ax, word ptr [ebp - 2]
    endIfMaxW:
                popfd                      ; restore flags
                pop    esi                 ; restore registers
                pop    edx
                pop    ebx
                mov    esp, ebp            ; delete local variable space
                pop    ebp 
                ret                        ; exit
atowproc    ENDP


DlgProc PROC
    ; DlgProc(HWND hDlg, UINT uMsg, WPARAM wParam, LPARAM lParam)
	;LOCAL len:dword         ; we added another word onto stack so we'll be off by 4 bytes than the cdecl protocol

    PUSH EBP                ; save current address that is stored in ebp onto stack
    MOV EBP, ESP            ; establish stack framework
    push ecx                ; save general perpose register

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
        ; Initialize the dialog box controls i.e set the text below the window title name (the Label --- view DialogBox.rc)
        invoke SetDlgItemTextA, edx, IDC_LABEL, offset inputLabel
        invoke SetDlgItemTextA, edx, IDC_TEXT, " "
        JMP Done
    HandleCommand:
        ; Handle command messages from controls
        CMP EBX, IDC_OK                             ; Check for OK button click !
        JE HandleOK
        ; ... other control ID checks ...
        cmp ebx, IDC_EXIT                           ; Check for Exit button click !
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
        invoke MessageBoxA, edx, offset noInputTitle, offset noInput, MB_OK
        jmp Done
        GreaterThanZero:
            ; get the string into our buffer and exit
            ; GetDlgItemText(hwnd, IDC_TEXT, buf, len + 1)
            inc eax
            invoke GetDlgItemTextA, edx, IDC_TEXT, offset buf, eax

            ; check string to see if it is a valid input
            lea eax, buf
            push eax
            call CheckStrFloatOrInt
            add esp, 4

            ; check eax for validity
            cmp eax, 0FFFFFFFFh
            je InvalidInput

            ; check eax for overflow
            ; specifically the 4 upper most bits if its value is bigger than binary 1000
            ; then an overflow has occured
            
            mov ebx, eax
            and ebx, 11110000000000000000000000000000b
            rol ebx, 4
            cmp ebx, 8
            jl IntegerConversion
            je FloatConversion
            ; OverFlow has occured
            OverFlow:
                invoke MessageBoxA, NULL, offset overFlowMsg, offset noInputTitle, NULL
                jmp Done
            InvalidInput:
                invoke MessageBoxA, NULL, offset invalMsg, offset noInputTitle, NULL
                jmp Done
            IntegerConversion:
                push eax
                invoke MessageBoxA, NULL, offset iConverMsg, offset goodTitle, NULL
                ; no need to force 31th bit to zero as this is already the case !
                pop eax

                mov ecx, eax
                mov edx, eax
                lea ebx, buf
                IntConvert:
                    push ebx
                    call atowproc
                    add esp, 4
                    push ax
                    ; increment to next digit
                    GetNextDigit:
                        inc ebx
                        ; eax contains the number of elements found within the string (the delimiter is a single whitespace ' ' character)
                        cmp byte ptr [ebx], ' '
                        jne GetNextDigit
                        inc ebx
                        loop IntConvert

                xchg ecx, edx
                InsertIntoIntArr:
                    pop word ptr [myWordArr + edx]
                    add edx, 2
                    loop InsertIntoIntArr
                jmp DoneConvertingAndInsertingArr
            FloatConversion:
                push eax
                invoke MessageBoxA, NULL, offset fConverMsg, offset goodTitle, NULL
                ; force 31th bit to zero to get correct size of array to be processed
                pop eax

                ; extract the correct value ... remove the leading 31th bit that is indicating that it is a float to
                ; get the correct value in eax which contains the number of elements found within the string (the delimiter is a single whitespace ' ' character)
                xor eax, 080000000h

                mov esi, eax
                mov edi, 0
                lea ebx, buf
                ; remember that single precision floating point is 32bits i.e REAL4
                FloatConvert:
                    push ebx
                    call atowproc
                    add esp, 4
                    ; the left side of decimal is stored in eax right now
                    ; process the right side of decimal and convert !
                    cmp byte ptr [ebx], '.'
                    je BeginingDecimal
                    GetRightSideDecimal:
                        inc ebx
                        cmp byte ptr [ebx], '.'
                        jne GetRightSideDecimal
                    BeginingDecimal:
                        inc ebx
                    ; .[0       0       0       0       ......  n]
                    ;   10^-1   10^-2   10^-3   10^-4   10^-n
                    mov dword ptr [ebp - 4], 10
                    finit                       ; clear out and initialize the floating point stack
                    fld1                        ; load 1.0 onto the floating point stack ST(0) ... after another push this value will be at ST(1) and so on with
                                                ; subsequent pushes onto stack untill memory overflow at ST(7) or we pop the floating point stack !

                    fild dword ptr [ebp - 4]    ; convert integer value to float representation and push it on to the floating point stack !

                    mov ecx, 0
                    mov edx, 1                  ; if ecx == edx then stop getting 10 rasied to the power of edx,ecx will get reset to zero and edx will get incremeneted
                                                ; before we convert the next character jumping to the next 10s place
                    ConvertRightSideDecimal:
                        ; no need to error check that has been handled already ... just go until we reach the null terminator !
                        cmp     BYTE PTR [ebx], 0  ; next character == null terminator ?
                        je      EndOfDigit           ; exit if end of string
                        cmp     byte ptr [ebx], ' '
                        je      EndOfDigit
                        GetTensFactor:
                            fdiv
                            fild dword ptr [ebp - 4]
                            inc ecx
                            cmp ecx, edx
                            jne GetTensFactor
                        ; lets use ecx register for ASCII to integer conversion ... then we will go through the FPU
                        mov     cl,[ebx]                 ; load ASCII character to CL register
                        and     cx,000Fh                 ; convert into ... integers '0-9' ~~ x30 - x39 so just grab first byte and get single-digit integer

                        ; now we can multiply it by our TensFactor to get the correct value for its position in the number !

                        mov     word ptr [ebp - 8], cx      ; load converted ascii to integer into memory so that we can push it onto the stack
                        fistp   dword ptr [ebp - 12]        ; clear the top of floating point stack that was set in GetTensFactorLoop

                        ; now that the stack is cleared of the previous 10 convert our newly ascii digit to integer into a floating point number and push onto floating point stack
                        fild    word ptr [ebp - 8]
                        fmul
                        cmp     edx, 1
                        jg      accumulate
                        jmp DoneConvertingCharacter
                        accumulate:
                            fadd
                        DoneConvertingCharacter:
                            inc     ebx                      ; increment character pointer

                            mov     ecx, 0                   ; get ecx ready for next character
                            inc     edx                      ; increment the tens position counter so that we obtain the correct 10^-n place for the conversion !
                        
                            ; get floating point stack ready for next character
                            fld1
                            fild    dword ptr [ebp - 12]
                            jmp     ConvertRightSideDecimal  ; go try next character
                    EndOfDigit:
                        ; we need to pop the stack twice in order for the correct value to appear in
                        ; st(0) because we are going to be pushing left side of digit
                        mov     word ptr [ebp - 8], ax      ; load converted ascii to integer into memory so that we can push it onto the stack
                        fild    word ptr [ebp - 8]

                        and     ax, 0F0h
                        shr     ax, 4
                        cmp     ax, 8
                        jge     NegAdd
                        fadd    st, st(3)
                        jmp StoreFloat
                        NegAdd:
                            mov     word ptr [ebp - 8], -1
                            fild    word ptr [ebp - 8]
                            fmulp   st(4), st(0)
                            fadd    st(0), st(3)
                        comment%
                                        WE HAVE THE CORRECT VALUE WITHIN THE FLOATING POINT STACK BUTTTTTTTTTTTTT
                         ==============================================================================================================================
                         depending on which decimal point number we are trying to represent in its single-precision floating point representation
                         may lead to rounding errors !
                         Rounding errors:
                           Not every decimal number can be expressed exactly as a floating point number.
                           This can be seen when entering "0.1" or "15.2" even ".4" and examining its binary conversion leads to an repeating bit
                           in the case of 15.2 we will recieve a single precision floating point number of 15.19999980926513671875 
                           which gives us a hexvalue of 0x41733333 ---- also confirmed by using REAL4 directive followed by 15.2 and the aforementioned
                           was seen in memory due to rounding error !
                         ==============================================================================================================================
                        %
                        StoreFloat:
                            cmp     edi, 0
                            jne     StoreNextElem
                            FirstElem:
                                fstp    dword ptr [myREAL4Arr]
                                dec     esi
                                cmp     esi, 0
                                je      DoneConvertingAndInsertingArr
                                inc     edi
                                jmp     FloatConvert
                            StoreNextElem:
                                fstp    dword ptr [myREAL4Arr + (edi*4)]
                                dec     esi
                                cmp     esi, 0
                                je      DoneConvertingAndInsertingArr
                                inc     edi
                                jmp     FloatConvert
            DoneConvertingAndInsertingArr:
                mov edx, [ebp+8]
                invoke EndDialog, edx, 0
                jmp Done
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

    pop esi
    pop edi
    pop ebp
    ret
getInput ENDP

main proc
    ; prompt the user to input a set of any real numbers ... if any number thats capture is of decimal value i.e. 1.54323 .... then
    ; treat the entire set as floating point if not then treat as whole numbers i.e all integers !
    input inputPrompt, userInputStr, 40
	xor eax, eax
	ret
main endp

CheckStrFloatOrInt PROC
    ; CheckStrFloatOrInt(string str) // given string MUST INCLUDE A NULL TERMINATOR AT THE END TO SIGNAL THE END OF THE STRING !
    push ebp
    mov ebp, esp

    push ebx
    push ecx
    push edx
    mov eax, [ebp + 8]

    mov dword ptr [ebp - 4], 0                                ; number of space ... to indicate how much items to push to array
    mov word ptr [ebp - 6], 0                                 ; set flag to indicate if, 0 a integer ... 1 a float .... or 2 a invalid float
    mov word ptr [ebp - 8], 0                                 ; if user keys in multiple entries use to check previous flag with current flag
ScanStrForValidInput:
    ; case if user enter's in number with a leading space
    WhileLeadingBlank:
        cmp    BYTE PTR [eax],' '           ; space?
        jne    EndWhileLeadingBlank         ; exit if not
        inc    eax                          ; increment character pointer
        jmp    WhileLeadingBlank            ; and try again
    EndWhileLeadingBlank:
    ; now we can check rest of string to see if integer or float or invalid !
    ; ... are we at the end of the string ?
    cmp byte ptr [eax], 0
    je  nothingEntered
    ; there are no more leading blanks and so lets check rest of string !
    ; to see if it is a valid integer or float
    FloatOrInteger:
        jmp WhileValidDigit
        SetFloatFlag:
            ; once our flag is of the value of 2 or more then it is a invalid number ... no need to check rest of string
            inc word ptr [ebp - 6]                                              ; increment our current float flag
            cmp word ptr [ebp - 6], 1                                           ; is it greater than 1 ? if so invalid
            jg  InvalidFloat


            ; if first element no need to check flags so continue onward
            cmp dword ptr [ebp - 4], 0
            je continueCheck

            mov edx, [ebp - 6]
            cmp word ptr [ebp - 8], dx
            je continue
            ; data types do not match
            invoke MessageBoxA, NULL, offset invalType, offset noInputTitle, NULL
            mov eax, 0FFFFFFFFh
            jmp Done
            continueCheck:
                cmp    byte ptr [eax + 1], '0'
                jnge   InvalidFloat
                cmp    BYTE PTR [eax + 1],'9'       ; next character <= '9'
                jnle   InvalidFloat                 ; not a digit if bigger than '9'
            continue:
                inc eax
           
        WhileValidDigit:
                cmp    BYTE PTR [eax],' '       ; multiple entries
                je     Space
                cmp    byte ptr [eax], '-'      ; catch case if negative num .... remember even amount of negs == positive num & odd negs == neg number
                je     NegSign
                jnge   EndWhileValidDigit       ; exit if not >= - ... the ascii value that is !
                cmp    byte ptr [eax], '.'
                je     SetFloatFlag
                cmp    byte ptr [eax], '0'
                jnge   EndWhileValidDigit
                cmp    BYTE PTR [eax],'9'       ; next character <= '9'
                jnle   EndWhileValidDigit       ; not a digit if bigger than '9'

                ; if next character is end of string then check flags
                cmp    byte ptr [eax + 1], 0
                je CheckFlags
                inc    eax                      ; increment character pointer
                jmp    WhileValidDigit          ; go try next character
        EndWhileValidDigit:
                ; not a valid digit
                ; check to see if it is the null terminator .... if we went thru the entire str then it is valid
                cmp byte ptr [eax], 0
                je ValidInputRecieved
                
                invoke MessageBoxA, NULL, offset invalDigit, offset noInputTitle, NULL
                ; set flag to notify that an error has occured
                mov eax, 0FFFFFFFFh
                jmp Done
            
        NegSign:
            cmp byte ptr [eax - 1], '0'
            jge EndWhileValidDigit
            cmp byte ptr [eax - 1], '.'
            je EndWhileValidDigit
            inc eax
            jmp WhileValidDigit
        Space:
            ; another element is going to appear
            ; use the stack to set another flag ... this time to keep value of current flag ... then check prev flag with current flag
            ; so that we are pushing the same data type into the array ! !
            ; error check case if ".[space]" which is not valid
            ; also error check "num [space]+ and break for error"
            inc dword ptr [ebp - 4]                     ; increment the amount of elements to be added into the array
            cmp byte ptr [eax - 1], ' '
            je EndWhileValidDigit
            cmp byte ptr [eax - 1], '0'
            jnge EndWhileValidDigit
            cmp byte ptr [eax - 1], '9'
            jnle EndWhileValidDigit
            ; valid character now we can reset the float flag
            push [ebp - 6]
            pop [ebp - 8]
            mov word ptr [ebp - 6], 0

            inc eax
            cmp byte ptr [eax], '-'
            je NegSign
            cmp byte ptr [eax], 0
            je EndWhileValidDigit
            jmp WhileValidDigit
        nothingEntered:
            invoke MessageBoxA, NULL, offset noInput, offset noInputTitle, NULL
            ; set flag to notify that an error has occured
            mov eax, 0FFFFFFFFh
            jmp Done
        InvalidInteger:
            invoke MessageBoxA, NULL, offset invalType, offset noInputTitle, NULL
            ; set flag to notify that an error has occured
            mov eax, 0FFFFFFFFh
            jmp Done
        InvalidFloat:
            invoke MessageBoxA, NULL, offset invalFloat, offset noInputTitle, NULL
            ; set flag to notify that an error has occured
            mov eax, 0FFFFFFFFh
            jmp Done
        CheckFlags:
                ; check float flags
                ; size > 0
                cmp dword ptr [ebp - 4], 0
                jg Check
                ; the only element within the given string no need to check flags
                inc eax
                jmp EndWhileValidDigit
                Check:
                    mov dx, [ebp - 6]
                    cmp word ptr [ebp - 8], dx
                    jne InvalidInteger
                    inc eax
                    jmp WhileValidDigit
        ValidInputRecieved:
                ; we are at the null terminator of the string basically the last or first element recieved for input
                ; so increment the place in the stack the we are using to tell us the size of the array that is to be filled !
                inc dword ptr [ebp - 4]
                invoke MessageBoxA, NULL, offset goodInput, offset goodTitle, NULL
                ; store results of operation in eax register
                ; we'll use bits 0->28th bit place to represent the number of spaces (i.e num of elements)
                ; 29->31th place will indicate a integer or float ! 0 or 1 respectively
                mov eax, dword ptr [ebp - 4]

                mov dx, word ptr [ebp - 6]
                cmp dx, 1
                je SetFlag
                jmp Done
                SetFlag:
                    xor eax, 10000000000000000000000000000000b
Done:
    pop edx
    pop ecx
    pop ebx
    pop ebp
    ret
CheckStrFloatOrInt endp

end