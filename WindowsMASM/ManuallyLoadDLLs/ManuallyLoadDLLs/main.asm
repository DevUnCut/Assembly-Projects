.386
.model flat,stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
include \masm32\include\user32.inc

includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib


.data
    LibName db "DLL_Skeleton.dll",0
    FunctionName db "MyCustomFunction",0
    DllNotFound db "Cannot load library",0
    AppName db "Load Library",0
    FunctionNotFound db "MyCustomFunction function not found",0

.data?
    hLib dd ?
    CustomFunctionAddr dd ?

.code
main:
        invoke LoadLibrary,addr LibName
        .if eax==NULL
                invoke MessageBox,NULL,addr DllNotFound,addr AppName,MB_OK
        .else
                mov hLib,eax
                invoke GetProcAddress,hLib,addr FunctionName
                .if eax==NULL
                        invoke MessageBox,NULL,addr FunctionNotFound,addr AppName,MB_OK
                .else
                        mov CustomFunctionAddr,eax
                        call [CustomFunctionAddr]
                .endif
                invoke FreeLibrary,hLib
        .endif
        invoke ExitProcess,NULL
end main
