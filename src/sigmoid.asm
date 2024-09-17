%use masm
section .text

global f32_sigmoid
global f32_sigmoid_d

; Compute the sigmoid(X) where X is an fp32 number
; Input:
;    rdi = address of input number X
;    rsi = address of output number
; Output:
;    DWORD PTR [rsi] = sigmoid(X)=e^X/(1+e^X)
; - based on the f32_exp function in fops.asm
f32_sigmoid:
	FLD DWORD PTR [rdi]  ;st0 = x

	FLDL2E               ;st0 = log2(e), st1 = x
	FMULP st1,st0        ;st0 = x*log2(e)
	FLD1                 ;st0=1, st1=x*log2(e)
	FLD st1              ;st0=x*log2(e), st1=1, st2=x*log2(e)
	FPREM                ;st0=fract(x*log2(e)), st1=1, st2=x*log2(e)
	F2XM1                ;st0=2^fract(x*log2(e))-1, st1=1, st2=x*log2(e)
	FADDP                ;st0=2^fract(x*log2(e)), st1=x*log2(e)
	FSCALE               ;st0=2^(fract(x*log2(e))+int(x*log2(e)))=2^(x*log2(e))=e^x, st1=x*log2(e)
	FXCH st1             ;st0=x*log2(e), st1=e^x
	FSTP st0             ;st0=e^x
	
	FLD1                 ;st0=1, st1=e^x
	FLD  st1             ;st0=e^x, st1=1, st2=e^x
	FADDP                ;st0=1+e^x, st1=e^x
	FDIVP st1,st0        ;st0=e^x/(1+e^x)
	
	FSTP DWORD PTR [rsi]
	RET

; Compute the derivative sigmoid(X) where X is an fp32 number
; Input:
;    rdi = address of input sigmoid(X); this must already be computed with f32_sigmoid
;    rsi = address of output sigmoid_d(X)
; Output:
;    DWORD PTR [rsi] = sigmoid_d(X)=sigmoid(X)(1-sigmoid(X))
; 
f32_sigmoid_d:
	FLD DWORD PTR [rdi]  ;st0 = s(x)
	
	FLD1                 ;st0=1, st1=s(x)
	FLD  st1             ;st0=s(x), st1=1, st2=s(x)
	FCHS                 ;st0=-s(x), st1=1, st2=s(x)
	FADDP                ;st0=1-s(x), st1=s(x)
	FMULP                ;st0=s(x)(1-s(x))
	
	FSTP DWORD PTR [rsi]
	RET
