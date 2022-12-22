.386
.model flat, stdcall
option casemap:none

; if i am not including the actual .inc file then i must use PROTO and prototype the function i would like to use !
;include S:\masm32\include\user32.inc
includelib S:\masm32\lib\user32.lib

include S:\masm32\include\kernel32.inc ; include file for system resources like ExitProcess ! !
includelib S:\masm32\lib\kernel32.lib
    WriteConsoleA PROTO :DWORD, :DWORD, :DWORD, :DWORD
    WriteConsoleW PROTO :DWORD, :DWORD, :DWORD, :DWORD
    GetStdHandle PROTO :DWORD
    MessageBoxW PROTO :DWORD, :DWORD, :DWORD, :DWORD
; we actually do not need the following definitions above since we are already including the kernel32.inc library
; and these functions are defined within that library but it makes for a easy reference !


; Lets say we would like to use the WriteConsole function but we dont know how
; well let have a look at its definition witin the windows win32.chm (programmer's reference) guide
; or by doing a little goolge search as well !

; the following is a c++ definition so we must FILL OUT A FORM PUSING
; EACH ITEM ONTO THE STACK BEFORE WE ARE ABLE TO CALL WriteConsole ... and remember that its return value is stored in eax !
;BOOL WriteConsole( HANDLE hConsoleOutput, // handle to a console screen buffer = since we want to print something to the console <terminal>
                                                                                 ; we need to get the handle to our console window
                                                                                 ; just like when working on c++ with getWindowHandle
                                                                                 ; we're not passing in an actual HANDLE structure just
                                                                                 ; the getter function with -10, -11, and -12 as an argument ! =
                    ;CONST VOID *lpBuffer, // pointer to buffer to write from   = push in a long pointer to the buffer (str to print) <integer>=
                    ;DWORD nNumberOfCharsToWrite, // number of characters to write  = push the legth of the string onto the stack ! =
                    ;LPDWORD lpNumberOfCharsWritten,// pointer to number of characters written = again if we dont care/need this var pass in 0 =
                    ;LPVOID lpReserved  // reserved ) = We don't need/care for this variable in our assembly conversion pass in NULL or zero 0 =

; windows call's its functions paramters in reverse order, so the first
; item within the stack should correspond to the last argument within the function definition !
; read my personal notes alongside c++ function definition above = blah blah = from bottom to top ! !

; windows is different but would but equivalent to linux 0, 1, 2
; in windows its (-10), (-11), and (-12) respectively
; HANDLE GetStdHandle( DWORD nStdHandle  // input, output, or error device)

; let us write a macro that'll insert qutations and a comma for us so we can us a
; prettier looking unicode string
ws MACRO varname:REQ, string:REQ, args:VARARG
    % @CatStr(<varname WORD >, !',@SubStr(string, 2, 1), !')

    % FORC chr, <@SubStr(string, 3, @SizeStr(string)-3)>
        WORD '&chr&'
    ENDM

    FOR arg, <args>
        WORD arg
    ENDM

ENDM

.data
    ansiSTR db 'I am an ansi string !', 13, 10, 0

    ; unicode is stuck in old school conventions so if we wanted the following we must
    ; encapsulate each char within their our set of quotations !
    ; 'h', 'e', 'l'
    ; WORD 'l'
    ; WORD 'l'
    ; WORD 'o', 0

    unicodeSTR WORD 'h','e','l','l','o'
    WORD ' '
    WORD 'i'
    WORD ' ','a', 'm',' ', 'a',' ','u','n','i','c','o','d','e',' ','s','t','r','i','n','g', 13, 10, 0

    ws uniSTR, "some string.", 13, 10, 0
.code
main:
    push 0
    push 0
    push 14
    ;push LENGTHOF ansiSTR
    push offset uniSTR
    push -11 ; STD_OUTPUT_HANDLE
    call GetStdHandle
    push eax
    ;call WriteConsoleA
    call WriteConsoleW

    invoke MessageBoxW, 0, OFFSET uniSTR, OFFSET unicodeSTR, 0

    push 0
    call ExitProcess
end main
end