%use masm
section .text
global matInit
global matConsoleWrite

extern osConsoleWrite
extern float32ToString

; Initialize matrix with float32 number
; Input:
;     eax = float32 number
;     rcx = line size (number of columns)
;     rdx = column size (number of lines)
;     rdi = matrix
matInit:
    PUSH rcx
    PUSH rdi
    PUSH rdx
    
    PUSH rax
    MOV rax,rcx
    MUL rdx
    MOV rcx,rax ; rcx=rcx*rdx
    POP rax
    
    REP STOSD
    
    POP rdx
    POP rdi
    POP rcx
    RET


; Write a matrix to console
; Input:
;     rdi = matrix
;     rcx = line size (number of columns)
;     rdx = column size (number of lines)
matConsoleWrite:
    PUSH rax
    PUSH rcx
    PUSH rsi
    PUSH rdi
    PUSH r8
    PUSH rdx

_mcw_loop:
    PUSH rcx                ; Will be decremented in the loop
    PUSH rdx                ; Will be changed for osConsoleWrite
    
_mcw_loop_disp_line:
    MOV eax, DWORD PTR [rdi]
    MOV r8, matfp32Buff
    CALL float32ToString

    MOV rsi, matfp32Buff
    MOV rdx, matfp32BuffSz
    CALL osConsoleWrite

    ADD rdi,4
    LOOP _mcw_loop_disp_line ; End loop for display line

    MOV rsi, matnl
    MOV rdx, matnlSz
    CALL osConsoleWrite

    POP rdx                  ; Restore rcx to be line size
    POP rcx                  ; Restore rdx to current line
    DEC rdx
    JZ  _mcw_done
    JMP _mcw_loop
    
_mcw_done:
    POP rdx
    POP r8
    POP rdi
    POP rsi
    POP rcx
    POP rax
    RET
    
section .data

matfp32Buff: DB "XXXXXXXXXXXXXXXXXXXXX "
    matfp32BuffSz EQU $-matfp32Buff
    
matnl: DB 13,10
    matnlSz EQU $-matnl
    
vec_tmp: DD 0
