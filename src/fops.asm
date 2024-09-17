%use masm
section .text

global f32_square
global f32_sqrt
global f32_exp
global f32_pow

; Compute the square value of a fp32 number
; Input:
;    rdi = address of input number X
;    rsi = address of output number
; Output:
;    DWORD PTR [rsi] = X*X
f32_square:
	FLD DWORD PTR [rdi]
	FMUL st0,st0
	FSTP DWORD PTR [rsi]
	RET

; Compute the square root of a fp32 number
; Input:
;    rdi = address of input number X
;    rsi = address of output number
; Output:
;    DWORD PTR [rsi] = sqrt(X)
f32_sqrt:
	FLD DWORD PTR [rdi]
	FSQRT
	FSTP DWORD PTR [rsi]
	RET

; Compute the e^X where X is an fp32 number
; Input:
;    rdi = address of input number X
;    rsi = address of output number
; Output:
;    DWORD PTR [rsi] = e^X = 2^(X*log2(e))
; https://stackoverflow.com/questions/48713712/calculating-expx-in-x86-assembly
;f32_exp:
;	FLD DWORD PTR [rdi] ;st0 = x
;	FLDL2E              ;st0 = log2(e), st1 = x
;	FMULP st1,st0       ;st0 = x*log2(e)
;	FLD1                ;st0 = 1, st1=x*log2(e)
;	FSCALE              ;st0 = 2^int(x*log2(e)), st1=x*log2(e)
;	FXCH                ;st0 = x*log2(e), st1=2^int(x*log2(e))
;	FLD1                ;st0 = 1, st1=x*log2(e), st2=2^int(x*log2(e))
;	FXCH                ;st0 = x*log2(e), st1=1, st2=2^int(x*log2(e))
;	FPREM               ;st0 = fract(x*log2(e)), st1=1, st2=2^int(x*log2(e))
;	F2XM1               ;st0 = 2^(fract(x*log2(e))) - 1, st1=1, st2=2^int(x*log2(e))
;	FADDP st1,st0       ;st0 = 2^(fract(x*log2(e))), st1 = 2^int(x*log2(e))
;	FMULP st1,st0       ;st0 = 2^(int(x*log2(e)) + fract(x*log2(e))) = 2^(x*log2(e))
;	FSTP DWORD PTR [rsi]
;	RET

; Compute the X^Y where X,Y are fp32 numbers
; Input:
;    rdi = address of input number X
;     r8 = address of input number Y
;    rsi = address of output number
; Output:
;    DWORD PTR [rsi] = X^Y = 2^(Y*log2(X))
; https://www.madwizard.org/programming/snippets?id=36
; https://stackoverflow.com/questions/4638473/how-to-powreal-real-in-x86
f32_pow:
	FLD DWORD PTR [r8]   ;st0=Y
	FLD DWORD PTR [rdi]  ;st0=X, st1=Y
	FYL2X                ;st0=Y*log2(X)
	FLD1                 ;st0=1, st1=Y*log2(X)
	FLD st1              ;st0=Y*log2(X), st1=1, st2=Y*log2(X)
	FPREM                ;st0=fract(Y*log2(X)), st1=1, st2=Y*log2(X)
	F2XM1                ;st0=2^fract(Y*log2(X))-1, st1=1, st2=Y*log2(X)
	FADDP                ;st0=2^fract(Y*log2(X)), st1=Y*log2(X)
	FSCALE               ;st0=2^(fract(Y*log2(X))+int(Y*log2(X)))=2^(Y*log2(X)), st1=Y*log2(X)
	FXCH st1             ;st0=Y*log2(X), st1=2^(Y*log2(X))
	FSTP st0             ;st0=2^(Y*log2(X))
	FSTP DWORD PTR [rsi]
	RET

; Compute the e^X where X is an fp32 number
; Input:
;    rdi = address of input number X
;    rsi = address of output number
; Output:
;    DWORD PTR [rsi] = e^X = 2^(X*log2(e))
; - based on the pow function above
f32_exp:
	FLD DWORD PTR [rdi]  ;st0 = x
	FLDL2E               ;st0 = log2(e), st1 = x
	FMULP st1,st0        ;st0 = x*log2(e)
	FLD1                 ;st0=1, st1=x*log2(e)
	FLD st1              ;st0=x*log2(e), st1=1, st2=x*log2(e)
	FPREM                ;st0=fract(x*log2(e)), st1=1, st2=x*log2(e)
	F2XM1                ;st0=2^fract(x*log2(e))-1, st1=1, st2=x*log2(e)
	FADDP                ;st0=2^fract(x*log2(e)), st1=x*log2(e)
	FSCALE               ;st0=2^(fract(x*log2(e))+int(x*log2(e)))=2^(x*log2(e)), st1=x*log2(e)
	FXCH st1             ;st0=x*log2(e), st1=2^(x*log2(e))
	FSTP st0             ;st0=2^(x*log2(e))
	FSTP DWORD PTR [rsi]
	RET
