.586
.model flat
.stack 4096

.data
    a DWORD 3
    b DWORD 9
    c_ DWORD 2
.code
; the following c++ pseudocode int discr(int a, int b, int c)
discr PROC
; this procedure will find the discriminate of a quadratic function i.e. a polynomial
; return the discriminant b*b-4*a*c in the EAX register
    push ebp ; save base pointer to stack .... also we are assuming that a, b and c have also been pushed to stack ! !
    mov ebp, esp ; establish the stack frame

    mov eax, 0 ; clear eax register to zero so that it may be used to return the discriminate
    mov ebx, [ebp+8] ; get c which is 8 bytes away from our stack pointer which currently is at ebx previous value ... 4 bytes after that is our ret address so 8 bytes till c is found
    mov ecx, [ebp+12] ; get b ... 4 bytes (dword) away from c
    imul ebx, [ebp+16] ; ebx = a*c
    imul ebx, 4
    neg ebx
    imul ecx, ecx ; b^2

    mov eax, ecx ; eax = b^2
    add eax, ebx ; eax = b^2 - 4ac
    pop ebp
    ret
discr endp

COMMENT%
    Write a value-returning procedure min2
    to find the smaller of two doubleword integer parameters.
COMMENT%

min2 PROC
    push ebp ; save the current state of the base pointer
    mov ebp, esp ; setup the stack framework

    mov eax, 0 ; clear the eax register so that it my hold the return value of this procedure

    mov ebx, [esp+8]
    mov ecx, [esp+12]
    cmp ecx, ebx
    jl OP2SMALLER
    mov eax, ebx
    pop ebp
    ret
    OP2SMALLER:
        mov eax, ecx
        pop ebp
        ret
min2 endp

COMMENT%
    Write a value-returning procedure max3 which
    finds the largest of three doubleword integer parameters.
COMMENT%

max3 PROC
    push ebp ; save current state of base pointer
    mov ebp, esp ; establish the stack framework

    mov eax, 0 ; clear the eax register so that it may be used to return the largest of the three dword params

    mov ebx, [ebp+8] ; get the 3rd param ... 4 bytes for current ebp address and another 4 bytes for the ret return address so 8 bytes till we reach the third parameter
    mov ecx, [ebp+12] ; get 2nd param
    mov edx, [ebp+16] ; get 1st param

    ; now we are ready to carry out the logic to return the largest value of the three
    cmp ebx, ecx
    jg CgreaterThanB
    ; c less than b ..
    ; is b greater than C ?
    cmp ecx, edx
    jg BgreaterThanC
    BGreaterThanC:
        mov eax, ecx
        pop ebp
        ret
    CgreaterThanB:
        cmp ebx, edx
        jg Cgreatest
        ; A > C > B
        mov eax, edx
        pop ebp
        ret
        Cgreatest:
            mov eax, ebx
            pop ebp
            ret
max3 endp


COMMENT%
    The volume of a pyramid with a rectangular base is given by the formula
    h*x*y/3, where h is the height of the pyramid, x is the length,
    and y is the width of the base. Write a procedure pVolume that
    implements the function described by the following C/C++ function

    int pVolume(int height, int length, int width) // return the volume of a pyramid with a rectangular base !
COMMENT%

pVolume PROC
    push ebp     ; save the current position of the base pointer !
    mov ebp, esp ; establish the stack framework

    ; Volume_pyramid = h*x*y/3
    mov eax, 0
    mov ebx, [ebp+8]    ; y = width
    mov ecx, [ebp+12]   ; x = length
    mov edx, [ebp+16]   ; h = height
    mov eax, ebx ; eax = y
    imul eax, ecx ; y*x
    imul eax, edx ; y*x*h
    mov ebp, 3
    mov edx, 0 ; recall that div and idiv use edx:eax as implied dividend
    div ebp
    pop ebp
    ret
pVolume endp

main PROC
    push c_
    push b
    push a
    call discr
    ; dont forget to remove the parameters that we've just pushed onto the stack !
    add esp, 12

    push c_
    push b
    call min2
    add esp, 8 ; again let us not forget to move the pointer back to the correct place so that it points to the top of the stack since we removed the parameters


   
    push c_
    push b   
    push a
    call max3
    add esp, 12

    push c_
    push b
    push a
    call pVolume
    add esp, 12
    ret
main endp
end