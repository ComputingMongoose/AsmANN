%use masm
section .text
global vecInit
global vecConsoleWrite
global vecMulScalar
global vecMulVecDot
global vecMulVecHadamard
global vecMulMatLines
global vecMulMatColumns
global vecCopy
global vecSigmoid
global vecSigmoid_d
global vecDiff
global vecAdd
global vecMulVecOuter

extern osConsoleWrite
extern float32ToString

extern f32_sigmoid
extern f32_sigmoid_d

; Initialize vector with float32 number
; Input:
;     eax = float32 number
;     rcx = vector size
;     rdi = vector
vecInit:
    PUSH rcx
    PUSH rdi
    REP STOSD
    POP rdi
    POP rcx
    RET


; Multiply the vector with a scalar value
; Input:
;     eax = float32 number
;     rdi = vector (this will be overwritten)
;     rcx = vector size, must be greater than zero
; Output:
;     rdi = vector * eax
vecMulScalar:
    PUSH rax
    PUSH rcx
    PUSH rdi
    MOV DWORD PTR [vec_tmp], eax ; store to temp location for passing to FP unit

_vms_loop:
    FLD DWORD PTR [vec_tmp]
    FMUL DWORD PTR [rdi]
    FSTP DWORD PTR [rdi]

    ADD rdi,4
    LOOP _vms_loop

    POP rdi
    POP rcx
    POP rax
    RET

; Multiply the vector with another vector and compute the dot product
; Input:
;     rdi = vector1
;     rsi = vector2
;     rcx = vector size
; Output:
;     eax = result
vecMulVecDot:
    PUSH rcx
    PUSH rdi
    PUSH rsi
    
    FLDZ
    
_vmvd_loop:
    FLD DWORD PTR [rdi]
    FMUL DWORD PTR [rsi]
    FADDP
    
    ADD rdi,4
    ADD rsi,4
    LOOP _vmvd_loop

    FSTP DWORD PTR [vec_tmp]
    MOV eax, DWORD PTR [vec_tmp]
    
    POP rsi
    POP rdi
    POP rcx
    RET

; Multiply the vector with another vector and compute the Hadamard product
; Input:
;     rdi = vector1 (this will be overwritten)
;     rsi = vector2
;     rcx = vector size
; Output:
;     rdi = vector1*vector2
vecMulVecHadamard:
    PUSH rcx
    PUSH rdi
    PUSH rsi

_vmvh_loop:
    FLD DWORD PTR [rdi]
    FMUL DWORD PTR [rsi]
    FSTP DWORD PTR [rdi]

    ADD rdi,4
    ADD rsi,4
    LOOP _vmvh_loop

    POP rsi
    POP rdi
    POP rcx
    RET


; Multiply a matrix with a vector, line by line
; Each matrix line is considered a vector and the dot product is computed
; Input:
;     rdi = vector1
;     rsi = matrix
;     rcx = vector size = line size (number of columns)
;     rdx = number of lines
;     r8  = output vector
; Output:
;     memory [r8 ... r8+rcx] = result
vecMulMatLines:
    PUSH rcx
    PUSH rsi
    PUSH r8
    PUSH rax
    PUSH rbx
    PUSH rdx
    
    MOV rbx,rcx
    SHL rbx, 2        ; Line size = rcx * 4
    
_vmml_loop:
    CMP rdx,0
    JZ _vmml_done

    CALL vecMulVecDot    ; line * vector
    MOV DWORD PTR [r8], eax  ; result in [r8]

    ADD rsi,rbx       ; next line
    ADD r8, 4
    DEC rdx
    JMP _vmml_loop

_vmml_done:

    POP rdx
    POP rbx
    POP rax
    POP r8
    POP rsi
    POP rcx
    RET


; Multiply a matrix with a vector, column by column (this is the regular vector matrix product)
; Each matrix column is considered a vector and the dot product is computed
; Input:
;     rdi = vector1
;     rsi = matrix
;     rcx = vector size = column size (number of lines)
;     rdx = number of columns (line size)
;     r8  = output vector
; Output:
;     memory [r8 ... r8+rcx] = result
vecMulMatColumns:
    PUSH rcx
    PUSH rsi
    PUSH r8
    PUSH rax
    PUSH rbx
    PUSH rdx
    
    MOV rbx,rdx
    SHL rbx, 2        ; Line size = rdx * 4
    
_vmvc_loop:
    CMP rdx,0
    JZ _vmvc_done

    ; CALL vecMulVecDot    ; this cannot be called, instead we need to implement the code here
    
    PUSH rcx
    PUSH rdi
    PUSH rsi
    
    FLDZ
    
_vmvc_loop1:
    FLD DWORD PTR [rdi]
    FMUL DWORD PTR [rsi]
    FADDP
    
    ADD rdi,4
    ADD rsi,rbx
    LOOP _vmvc_loop1

    FSTP DWORD PTR [r8]
    
    POP rsi
    POP rdi
    POP rcx
    
    ADD rsi, 4       ; next column
    ADD r8, 4
    DEC rdx
    JMP _vmvc_loop

_vmvc_done:
    POP rdx
    POP rbx
    POP rax
    POP r8
    POP rsi
    POP rcx
    RET

; Write a vector to console
; Input:
;     rdi = vector
;     rcx = vector size
vecConsoleWrite:
    PUSH rax
    PUSH rcx
    PUSH rsi
    PUSH rdi
    PUSH r8
    PUSH rdx

_vcw_loop:
    MOV eax, DWORD PTR [rdi]
    MOV r8, vecfp32Buff
    CALL float32ToString

    MOV rsi, vecfp32Buff
    MOV rdx, vecfp32BuffSz
    CALL osConsoleWrite

    ADD rdi,4
    LOOP _vcw_loop

    POP rdx
    POP r8
    POP rdi
    POP rsi
    POP rcx
    POP rax
    RET

; Copy vector1 to vector 2
; Input:
;     rdi = vector1
;     rsi = vector2
;     rcx = vector size
vecCopy:
    PUSH rcx
    PUSH rsi
    PUSH rdi
    
    XCHG rsi,rdi
    REP MOVSD
    
    POP rdi
    POP rsi
    POP rcx
    RET

; Apply the sigmoid function on vector1 and store in vector 2
; Input:
;     rdi = vector1
;     rsi = vector2
;     rcx = vector size
vecSigmoid:
    PUSH rcx
    PUSH rsi
    PUSH rdi
    
_vc_loop:
    call f32_sigmoid
    ADD rsi,4
    ADD rdi,4
    LOOP _vc_loop
    
    POP rdi
    POP rsi
    POP rcx
    RET

; Apply the sigmoid derivation function on vector1 and store in vector 2
; Input:
;     rdi = vector1
;     rsi = vector2
;     rcx = vector size
vecSigmoid_d:
    PUSH rcx
    PUSH rsi
    PUSH rdi
    
_vcd_loop:
    call f32_sigmoid_d
    ADD rsi,4
    ADD rdi,4
    LOOP _vcd_loop
    
    POP rdi
    POP rsi
    POP rcx
    RET

; Add two vectors
; Input:
;     rdi = vector1 (this will be overwritten)
;     rsi = vector2
;     rcx = vector size
; Output:
;     rdi = vector1+vector2
vecAdd:
    PUSH rcx
    PUSH rdi
    PUSH rsi

_va_loop:
    FLD DWORD PTR [rdi]
    FADD DWORD PTR [rsi]
    FSTP DWORD PTR [rdi]

    ADD rdi,4
    ADD rsi,4
    LOOP _va_loop

    POP rsi
    POP rdi
    POP rcx
    RET

; Subtract two vectors
; Input:
;     rdi = vector1 (this will be overwritten)
;     rsi = vector2
;     rcx = vector size
; Output:
;     rdi = vector1-vector2
vecDiff:
    PUSH rcx
    PUSH rdi
    PUSH rsi

_vd_loop:
    FLD DWORD PTR [rdi]
    FSUB DWORD PTR [rsi]
    FSTP DWORD PTR [rdi]

    ADD rdi,4
    ADD rsi,4
    LOOP _vd_loop

    POP rsi
    POP rdi
    POP rcx
    RET

; Multiply one vector with another vector and compute the outer product
; The result is a matrix
; Input:
;     rdi = vector1
;     rsi = vector2
;     rcx = vector1 size = line size (number of columns)
;     rdx = vector2 size = column size (number of lines)
;      r8 = output matrix (must have space vec1_size x vec2_size)
; Output:
;      [r8] = vector1*vector2
vecMulVecOuter:
    PUSH rcx
    PUSH rdi
    PUSH rsi
    PUSH rdx

_vmvc_loop_v2:
    PUSH rcx
    PUSH rdi
    FLD DWORD PTR [rsi]
    
_vmvc_loop_v1:
    FLD st0
    FMUL DWORD PTR [rdi]
    FSTP DWORD PTR [r8]

    ADD rdi,4
    ADD r8,4
    LOOP _vmvc_loop_v1
    
    FSTP st0
    POP rdi
    POP rcx
    ADD rsi,4
    DEC rdx
    jnz _vmvc_loop_v2
    
    POP rdx
    POP rsi
    POP rdi
    POP rcx
    RET

    
section .data

vecfp32Buff: DB "XXXXXXXXXXXXXXXXXXXXX",13,10
    vecfp32BuffSz EQU $-vecfp32Buff
    
vec_tmp: DD 0
