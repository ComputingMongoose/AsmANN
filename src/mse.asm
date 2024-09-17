%use masm
section .text
global vecMSE

; Compute the Mean Square Error (MSE) between two vectors
; Input:
;     rdi = vector1
;     rsi = vector2
;     rcx = vector size
; Output:
;     eax = result
vecMSE:
    PUSH rcx
    PUSH rdi
    PUSH rsi
    
    MOV DWORD PTR [tmp], ecx
    FILD DWORD PTR [tmp]       ; st0=N
    
    FLDZ                       ; st0=0, st1=N
    
_vmse_loop:
    FLD DWORD PTR [rdi]        ; st0=Ai, st1=0, st2=N
    FSUB DWORD PTR [rsi]       ; st0=Ai-Bi, st1=0, st2=N
    FMUL st0,st0               ; st0=(Ai-Bi)^2, st1=0, st2=N
    FADDP                      ; st0=sum((Ai-Bi)^2), st1=N
    
    ADD rdi,4
    ADD rsi,4
    LOOP _vmse_loop

                               ; st0=sum((Ai-Bi)^2), st1=N
    FXCH                       ; st0=N, st1=sum((Ai-Bi)^2)
    FDIVP                      ; st0=sum((Ai-Bi)^2) / N

    FSTP DWORD PTR [tmp]
    MOV eax, DWORD PTR [tmp]
    
    POP rsi
    POP rdi
    POP rcx
    RET
    
section .data

tmp: DD 0
