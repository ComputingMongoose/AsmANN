%use masm
section .text
extern uint4ToHexString
extern uint32ToHexString
extern uint32ToString      ; this is an alias to uint32ToString10
extern uint32ToString9
extern uint32ToString10
extern uint32ToString_internal
extern float32ToString

; Converts an int 4 (possible values 0-15) to a hex digit
; Input:
;     AL=number
;     R8=string position
; Output:
;     AL=hex digit ('0'-'F')
;     R8=R8+1
uint4ToHexString: ; digit in al, position in r8, al is modified
	AND al,0Fh
	CMP al,0Ah
	JC _uint4ToHexString_0
	ADD al,'A'-10
	JMP _uint4ToHexString_disp
_uint4ToHexString_0:
	ADD al,'0'
_uint4ToHexString_disp:
	MOV byte ptr [r8], al
	INC r8
	RET

; Converts an uint32 to a hex string
; Input:
;     EAX = dword uint32 value
;     R8 = string position
; Output:
;     R8 = R8 + 8
uint32ToHexString: ; dword in eax, position in r8, uses stack to save/restore registers
	PUSH rax           ; save RAX
	PUSH rcx           ; save RCX
	
	MOV CL, 32
	PUSH rax           ; working rax
_uint32ToHexString_for_digit:
	POP rax
	PUSH rax
	SUB cl,4
	SHR eax, cl
	CALL uint4ToHexString ; will increment R8
	CMP cl,0
	JNZ _uint32ToHexString_for_digit
	POP rax            ; clear the working rax

	POP rcx            ; restore rcx
	POP rax            ; restore RAX
	RET

; Converts an uint32 to a decimal string.
; The resulting string will be prefixed with zeros.
; Similar to printf("%010d").
; Input:
;     EAX = dword uint32
;     R8 = string position
; Output:
;     R8 = R8 + 10
uint32ToString: 
uint32ToString10:
	PUSH rsi
	MOV rsi, conv_table_int

	CALL uint32ToString_internal
	
	POP rsi
	RET

; Similar to uint32ToString, but will only use 9 digits.
; Similar to printf("%09d")
; Input:
;     EAX = dword uint32
;     R8 = string position
; Output:
;     R8 = R8 + 9
uint32ToString9: 
	PUSH rsi
	MOV rsi, conv_table_int
	ADD rsi, 4
	
	CALL uint32ToString_internal
	
	POP rsi
	RET

; Internal function called by uint32ToString and uint32ToString9
; Input:
;     EAX = dword uint32
;     R8 = string position
;     RSI = conv_table_int position
; Output:
;     R8 = R8 + sz
uint32ToString_internal:
	PUSH rax
	PUSH rbx
	PUSH rcx
	PUSH rdx
	PUSH rsi
_uint32ToString_loop:
	XOR edx,edx
	MOV ecx, DWORD PTR [rsi]
	CMP ecx,0
	jz _uint32ToString_done
	DIV ecx        ; divide edx:eax to ecx => eax = quotient, edx = reminder
	ADD al, '0'
	MOV byte ptr [r8], al
	INC r8
	MOV eax, edx
	ADD rsi,4
	JMP _uint32ToString_loop
_uint32ToString_done:
	POP rsi
	POP rdx
	POP rcx
	POP rbx
	POP rax
	RET

; Converts a float32 (IEEE 754 standard) to a decimal string.
; The resulting string will occupy 21 bytes (example: +0000009999.990234375).
; Input:
;     EAX = float32
;     R8 = string position
; Output:
;     R8 = R8 + 20
float32ToString: ; float32 dword in eax, position in r8
	PUSH rax
	PUSH rbx
	PUSH rcx
	PUSH rsi
	PUSH rdi
	
	TEST eax, 80000000h
	JNZ _f32s_neg
	MOV BYTE PTR [r8], '+'
	JMP _f32s_exp
_f32s_neg:
	MOV BYTE PTR [r8], '-'
	
_f32s_exp:
	INC r8
	PUSH rax
	MOV cl, 23      ; separate exponent
	SHR rax, cl
	AND rax, 0FFh
	MOV rcx,rax      ; exponent now in rcx
	;CALL uint32ToString
	POP rax
	
	AND rax,7FFFFFh ; separate mantissa
	OR  rax,800000h ; add missing first 1 bit
	SHL rax, 9      ; upper part of rax=integer, eax=decimals
	
	CMP rcx,127
	JZ _f32s_exp_done
	JC _f32s_exp_neg
	SUB rcx, 127    ; rcx = exponent - 127, is positive
	SHL rax, cl     ; multiply with exponent
	JMP _f32s_exp_done
_f32s_exp_neg:
	ADD rcx, 128
	NEG rcx
	AND rcx, 07Fh
	SUB rcx, 1      ; rcx = abs(exponent - 127), exponent was negative
	SHR rax, cl     ; multiply with exponent
_f32s_exp_done:

	PUSH rax
	XOR rbx,rbx
	SHLD rbx,rax,32
	MOV rax,rbx
	CALL uint32ToString10
	MOV BYTE PTR [r8], "."
	INC r8
	POP rbx
	
	XOR rax,rax
	MOV rsi,conv_table_f32
	MOV rcx, 32
	MOV rdi,80000000h
_f32s_frac:
	TEST rbx,rdi
	JZ _f32s_frac_skip
	ADD eax, DWORD PTR [rsi]
_f32s_frac_skip:
	ADD rsi,4
	SHR rdi,1
	LOOP _f32s_frac
	
	CALL uint32ToString9
	
	POP rdi
	POP rsi
	POP rcx
	POP rbx
	POP rax

	RET
	


section .data

conv_table_int:
	DD 1000000000, 100000000, 10000000, 1000000, 100000, 10000, 1000, 100, 10, 1, 0

conv_table_f32:
	; truncated
	;DD 500000000, 250000000, 125000000,  62500000,  31250000,  15625000,   7812500,   3906250 
	;DD   1953125,    976562,    488281,    244140,    122070,     61035,     30517,     15258 
	;DD      7629,      3814,      1907,       953,       476,       238,       119,        59
	;DD        29,        14,         7,         3,         1,         0,         0,         0

	; rounded
	DD 500000000, 250000000, 125000000,  62500000,  31250000,  15625000,   7812500,   3906250 
	DD   1953125,    976563,    488281,    244141,    122070,     61035,     30518,     15259 
	DD      7629,      3815,      1907,       954,       477,       238,       119,        60
	DD        30,        15,         8,         4,         2,         1,         0,         0
	

