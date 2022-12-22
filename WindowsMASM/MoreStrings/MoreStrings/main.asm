.386
.model flat, stdcall

option casemap:none

include S:\masm32\include\user32.inc
includelib S:\masm32\lib\user32.lib
ExitProcess PROTO :dword

.data
window_title db "my window", 0
uni_title word 'm','y',' ', 'w','i','n',13, 10, 0

msg db "hello moto !",13, 10, 0
msg2 word 'w', 't', 'f', 't', 'r', 'u','e',13, 10, 0

txt db  ?

.data?
txt2 dw ?


.code
main:
    ; the following section of code will work with ansi strings !
    cld ; clear the direction flag defaults to zero 0 which is forward !
    mov esi, offset msg
    mov edi, offset txt
    L1:
        mov al, [esi]
        inc esi
        mov [edi], al
        inc edi
        cmp al, 0
        jne L1
    invoke MessageBoxA, 0, offset txt, offset window_title, 0

    cld
    mov esi, offset msg2
    mov edi, offset txt2
    L2:
        mov ax, [esi]
        inc esi
        mov [edi], ax
        inc edi
        cmp ax, 0
        jne L2
    invoke MessageBoxW, 0, offset txt2, offset uni_title, 0
    invoke MessageBoxA, 0, offset txt, offset window_title, 0
    invoke MessageBoxW, 0, offset txt2, offset uni_title, 0
    invoke MessageBoxA, 0, offset txt, offset window_title, 0

    invoke ExitProcess, 0
end main
end