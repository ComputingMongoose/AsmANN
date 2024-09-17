%use masm
section .text
global layerForward
global outputLoss
global layerBackward

extern vecMulMatLines
extern vecSigmoid
extern vecSigmoid_d
extern vecMSE
extern vecMulVecOuter
extern vecMulScalar
extern vecMulVecHadamard
extern vecDiff
extern vecConsoleWrite
extern matConsoleWrite

; Forward pass of a single layer
; Input:
;     rdi = input vector
;     rsi = Weights matrix
;     rcx = vector size = line size (number of columns)
;     rdx = number of lines
;     r8  = output vector
; Output:
;     memory [r8 ... r8+rcx] = result = sigmoid(W*x)
layerForward:
	PUSH rdi
	PUSH rsi
	
	CALL vecMulMatLines
	MOV rdi, r8
	MOV rsi, r8
	XCHG rcx, rdx
	CALL vecSigmoid
	XCHG rcx, rdx
	
	POP rsi
	POP rdi
	RET
	
; Computes the loss using the Mean Squared Error (MSE)
; Input:
;      rdi = output
;      rsi = expected
;      rcx = vector size
; Output:
;      eax = result = MSE loss
outputLoss:
	JMP vecMSE

; Updates the Weights matrix using backpropagation
; Input:
;      rdi = output
;      rsi = expected
;      rcx = output size
;      eax = eta (learning rate)
;       r9 = input
;      rdx = input size
;      r10 = weights (size = rcx lines, r10 columns)
layerBackward:
	PUSH rdi
	PUSH rcx
	PUSH rdx
	PUSH r8
	PUSH rax
	PUSH rsi
	
	PUSH rsi
	MOV rsi, tmpOut
	CALL vecSigmoid_d ; tmpOut=SigmoidDeriv(output)
	POP rsi
	
	CALL vecDiff      ; output=output-expected
	
	PUSH rsi
	MOV rsi, tmpOut
	CALL vecMulVecHadamard ; output=(out-expected)*SigmoidDeriv()
	POP rsi
	
	CALL vecMulScalar      ; output=eta*(out-expected)*SigmoidDeriv()
	
	MOV  rsi, rdi
	MOV  rdi, r9
	XCHG rcx,rdx
	MOV r8, tmpW
	; rsi = output
	CALL vecMulVecOuter    ; tmpW=weights adjustment
	
	MOV rax, rdx
	MUL rcx                ; rax = cols*lines
	MOV rcx,rax
	MOV rdi, r10
	MOV rsi, tmpW
	CALL vecDiff           ; weights get updated
	
	POP rsi
	POP rax
	POP r8
	POP rdx
	POP rcx
	POP rdi
	RET
	
debugTmpOut:
	PUSH rdi
	PUSH rcx
	MOV rdi, tmpOut
	MOV rcx, 2
	call vecConsoleWrite
	POP rcx
	POP rdi
	RET

debugTmpW:
	PUSH rdi
	PUSH rcx
	PUSH rdx
	MOV rdi, tmpW
	MOV rcx, 3
	MOV rdx, 2
	call matConsoleWrite
	POP rdx
	POP rcx
	POP rdi
	RET
	
section .data

tmpOut: DD 100 dup(0) ; Temporary space to store a copy of the output vector

tmpW: DD 100 dup(0)   ; Temporary space to store weight changes
