.586
.model flat
.stack 4096

include \masm32\include\user32.inc
includelib \masm32\lib\user32.lib

.data
msg BYTE "hHolyFGDF macGoly",0
nums dword 45, 1, 47, 5, 2, 0, 14, 4
result dword 0
.code

COMMENT%
	Suppose that a procedure is described in C/C++ by 
	void toUpper(char str[]), that is, its name is toUpper, and it has a single
	parameter that is the address of an array of characters. Assuming that
	the character string is null-terminated, implement toUpper so that it
	changes each lowercase letter in the string to its uppercase
	equivalent, leaving all other characters unchanged.
COMMENT%

toUpper PROC
	push ebp ; save current ebp to stack
	mov ebp, esp ; establish the stack framework

	; save status of registers
	push eax ; we'll be using the eax -> ax -> ah -> al register to temporarily hold a byte of data until
			; we determine wheather it is a uppercase character already, an invalid character or a lowercase char that needs to be capitalized

	push esi ; we'll be using this to hold the starting address of the array

	; this procedure expects that a character array is the first argument on the stack
	; we are accepting a character array with the first byte --- given ascii encoding, unicode is 2 bytes
	; also recall that the ESI register and EDI register are index registers with ESI being the source index and EDI being the destination index !

	mov esi, [ebp+8] ; get the starting address of the character array
	ForElem:
		mov al, [esi] ; get the first byte
        cmp al, 0 ; if end of string ... null terminator
		jz EXITLOOP
		; ================================
		; lower case ? hex 61 - hex 7A
		cmp al, 07ah
		jg EXITLOOP
		cmp al, 061h
		jl UPPER ; upper case already ? or invalid char ? or Space char ?
		; x7A >= al >= x61
		sub al, 020h
		mov BYTE PTR [esi], al ; replace the current byte of the lowercase chara
		inc esi	; increment the address to get the next byte
		jmp ForElem
		UPPER:
			cmp al, 05Ah
			jg EXITLOOP ; invalid char
			cmp al, 020h ; space character skip this one too
			je SKIP
			cmp al, 041h
			jl EXITLOOP ; not a valid char
			inc esi
			jmp ForElem
		SKIP:
			inc esi
			jmp ForElem
		EXITLOOP:
			pop esi
			pop eax
			pop ebp
			ret
toUpper endp




COMMENT%
	IMPLEMENT THE C++ ALGORITHM FOR SELECTION SORT ! !
	here is the header for the c++ function
	void selectionSort(int nbrArray[], int nbrElts)

	sort nbrArray[0] .. nbrArray[nbrElts?1]
	into increasing order using selection sort
	The first parameter will be the address of the array.
COMMENT%

selectionSort PROC
	push ebp ; save current state of base pointer
	mov ebp, esp ; establish the stack framewordk

	push esi
	push edi
	push eax
	push ebx
	push ecx
	push edx

COMMENT%
	  since there are no predefined for, while, do while, etc ...
	  we must use 2 registers to hold the values for the current iteration and 
	  prepare sizeOfArray and the memory address of the beginning of the array
COMMENT%
	mov eax, 0 ; counter for outter loop -- i
	mov ecx, 0 ; this will be used to temporarily hold the swap value so we dont lose track of it !
	mov edx, 1 ; lets use the edx register as a boolean to indicate when we have done a swap !
				  ; akin to bool haveISwapped = true

	mov esi, [ebp+8]	; put second parameter into the esi index --- the starting address of the array
	mov edi, [ebp+12]	; put the first parameter into the edi register -- the size of the array
	dec edi ; correct it so that it corresponds to the index of the last element
whileHaveISwapped:
	; a while(true) {} loop ... edx is already true ... while not true exit the while loop
	cmp	edx, 0
	je	completelySorted ; while the outter index is greater than or equal to the size of the array terminate the outter for loop !
	; we still have sorting to do !
	; let's ready up the next counter which will be for getting the i+1 element within the array to check for the condition if arr[i] >= arr[i+1] ? then swap
;	mov	ebx, eax
;	inc ebx
	mov edx, 0
foriLessArraySize:
	; lets check to see if i < sizeOfArray -1?
	cmp	eax, edi
	je	exitFori ; while the inner index is greater than or equal to the size of the array terminate the inner most loop !
ifCondition:
	; check to see if arr[i] > arr[i+1] then swap if true
	; remeber that we are dealing with memory addresses so lets dereference it in c++ terms
	; in assembly that means we are doing a register -> register (memory indirect addressing mode)
	; then we can look up the accompaning op code within the op code tables
	
	mov ecx, dword ptr [esi+eax*4] ; get the i th   element
	mov ebx, eax
	inc ebx
	imul ebx, 4
	add ebx, esi
	mov ebx, dword ptr [ebx]
	cmp ecx, ebx ; now compare it with the current (i+1 th) element !

	jl skipElem ; if arr[j] > arr[i] then skip element since it is in its correct place

	; now swap values since arr[j] < arr[i] ! !
	mov dword ptr [esi+eax*4], ebx

	mov ebx, eax
	inc ebx
	imul ebx, 4
	add ebx, esi
	mov dword ptr [ebx], ecx

	; now set the flag and increment i i++
	mov edx, 1
	inc eax
	jmp foriLessArraySize
exitFori:
	mov eax, 0 ; reset i back to the beginning of the array and loop back to while loop
	mov edx, 1 ; reset flag back to true to enter the loop
	jmp whileHaveISwapped
skipElem:
	inc eax
	; check flag and check i <= arrSize -1
	cmp eax, edi
	je haveSwapped
	jmp foriLessArraySize
haveSwapped:
	; check the flag to see if a swap occured
	cmp edx, 0
	jge whileHaveISwapped
completelySorted:
	pop edx
	pop ecx
	pop ebx
	pop eax
	pop edi
	pop esi
	pop ebp
	ret
selectionSort endp

COMMENT%
	Write a procedure avg to find the average of a collection of
	doubleword integers in an array. Procedure avg will have three
	parameters in the following order:
		(1) The address of the array.
		(2) The number of integers in the array (passed as a doubleword).
		(3) The address of a doubleword at which to store the result.
	void Avg(int arr[], int sizeOfArray, int* result)
%

avg PROC
	push ebp ; save the current base pointer !
	mov ebp, esp ; establish stack framework 
	push eax
	push ebx
	push ecx
	push edx
	push edi

	; use the EBX register to contain the address of the dword currently being accessed
	mov ebx, [ebp + 8]		; the starting address of the array
	mov ecx, [ebp + 12]		; size of the array
	mov eax, [ebp + 16]		; address of the address which will be used to store the result !

	jecxz EXIT
forLoop:
	mov edi, dword ptr [ebx]
	add dword ptr [eax], edi			; add current element to the ongoing sum that is sum += arr[i]
	add ebx, 4				; add 4 bytes to get the next dword integer which prepares it for the next time we loop back around !
	loop forLoop			; loop back to forLoop until ecx register is zero !

	; after we've completely looped through the entire array and got the ongoing sum, now we can calculate the average !
	mov ecx, [ebp+12]	; get the number of elements
	mov edi, eax		; save the memory address of current element !
	
	mov eax, dword ptr [eax]	; get the actual value from the memory location
	cdq							; extends eax -- (double word) --  to a quadword thats stored in edx:eax

	idiv ecx
	mov dword ptr [edi], eax	; put the quotient of the operation back into the memory address of the dword that is to store the result
	EXIT:
		pop edi
		pop edx
		pop ecx
		pop ebx
		pop eax
		pop ebp
		ret
avg endp

COMMENT%
	Write a value-returning procedure search to search an array of
	doublewords for a specified doubleword value. Procedure search will
	have three parameters:
		(1) The value for which to search (a doubleword integer).
		(2) The address of the array.
		(3) The number n of doublewords in the array (passed as a doubleword).
	
	Return the position (1,2, . . .,n) at which the value is found, or return
		0 if the value does not appear in the array.
%

search PROC
	push ebp		; save current base pointer to stack !
	mov ebp, esp	; establish the stack framework

	; push eax .... we want to return the position at which the value is found that is the eax register will hold this value
	push ebx
	push ecx
	push edx
	push edi

	mov ebx, [ebp + 8]	; get the value to search the array for !
	mov edx, [ebp + 12] ; get the starting address of the array
	mov ecx, [ebp + 16] ; get the size of the array ! !

	mov edi, 1 ; keep track of the ongoing index
	; now we can iterate through the array to search for the value
	jecxz notFound
	ForLoopi:
		cmp ebx, dword ptr [edx]
		je Found
		; match not found increment address of array to obtain next element and loop back to the top
		add edx, 4
		inc edi
		loop ForLoopi
	notFound:
		mov eax, 0
		pop edi
		pop edx
		pop ecx
		pop ebx
		pop ebp
		ret
	Found:
		; we found a match return the memory address
		mov eax, edi
		pop edi
		pop edx
		pop ecx
		pop ebx
		pop ebp
		ret
search endp

main PROC
	lea eax, msg
	push eax
	call toUpper
	add esp, 4 ; a memory address was pushed onto stack which 
	invoke MessageBoxA, 0, offset msg, 0, 0

	pushd 8
	lea eax, nums
	push eax
	call selectionSort
	add esp, 8


	lea eax, result
	push eax
	pushd 8
	lea eax, nums
	push eax
	call avg
	add esp, 12


	pushd 8
	lea eax, nums
	push eax
	pushd -1
	call search
	add esp, 12
	ret
main endp
end