%use masm
section .text
global main
extern osInit
extern osConsoleWrite
extern osExit
extern vecInit
extern vecConsoleWrite
extern vecMulScalar
extern vecMulVecDot
extern vecMulVecHadamard
extern float32ToString
extern vecMulMatLines
extern vecMulMatColumns
extern matInit
extern matConsoleWrite
extern vecMSE
extern layerForward
extern outputLoss
extern layerBackward
extern uint32ToString

main: ; Main entry point. Will run tests for the vector functions

	CALL osInit

; Print all input/expected output data
	MOV rsi, msgInput
	MOV rdx, msgInputSz
	CALL osConsoleWrite
	MOV rdi, in_data
	MOV rcx, in_cols
	MOV rdx, in_rows
	CALL matConsoleWrite

	MOV rsi, msgExpectedOutput
	MOV rdx, msgExpectedOutputSz
	CALL osConsoleWrite
	MOV rdi, expected_data
	MOV rcx, expected_cols
	MOV rdx, expected_rows
	CALL matConsoleWrite 

	MOV rbx,0    ; Epoch number

; EPOCH START
epoch_start:
	; Display current epoch number
	MOV rsi, msgEpoch
	MOV rdx, msgEpochSz
	CALL osConsoleWrite
	MOV rax, rbx
	MOV r8, uint32buff
	CALL uint32ToString
	MOV rsi, uint32buff
	MOV rdx, uint32buffSz
	CALL osConsoleWrite

data_start:
	XOR r14,r14 ; data index
	MOV r12, in_data
	MOV r13, expected_data
	
data_loop:
	; Display input
	MOV rsi, msgInput
	MOV rdx, msgInputSz
	CALL osConsoleWrite
	MOV rdi, r12
	MOV rcx, in_cols
	CALL vecConsoleWrite

	; Display expected output
	MOV rsi, msgExpectedOutput
	MOV rdx, msgExpectedOutputSz
	CALL osConsoleWrite
	MOV rdi, r13
	MOV rcx, expected_cols
	CALL vecConsoleWrite 

	; Run the forward step
	MOV rdi, r12
	MOV rsi, weights_data
	MOV rcx, in_cols
	MOV rdx, out_size
	MOV r8, out_data
	CALL layerForward

	; Display predicted output
	MOV rsi, msgOutput
	MOV rdx, msgOutputSz
	CALL osConsoleWrite
	MOV rdi, out_data
	MOV rcx, out_size
	CALL vecConsoleWrite 

	; Compute loss
	MOV rdi, out_data
	MOV rsi, r13
	MOV rcx, out_size
	CALL outputLoss
	
	; Display loss
	MOV rsi, msgLoss
	MOV rdx, msgLossSz
	CALL osConsoleWrite
	MOV r8, f32buff
	CALL float32ToString
	MOV rsi, f32buff
	MOV rdx, f32buffSz
	CALL osConsoleWrite

	MOV rdi, out_data
	MOV rsi, r13
	MOV rcx, out_size
	MOV eax, __?float32?__(0.1)
	MOV r9, r12
	MOV rdx, in_cols
	MOV r10, weights_data
	call layerBackward

	; Display weights
	MOV rsi, msgWeights
	MOV rdx, msgWeightsSz
	CALL osConsoleWrite
	MOV rdi, weights_data
	MOV rcx, weights_cols
	MOV rdx, weights_rows
	CALL matConsoleWrite 

	ADD r12, in_line_size
	ADD r13, expected_line_size
	INC r14
	CMP r14, in_rows
	JNZ data_loop

	INC rbx
	CMP rbx, 1000           ; number of epochs
	JNZ epoch_start
	
	CALL osExit
	RET ; this will never be executed

section .data

msgInput: DB 13,10,"Input: ",13,10
    msgInputSz EQU $-msgInput

msgExpectedOutput: DB 13,10,"Expected Output: ",13,10
    msgExpectedOutputSz EQU $-msgExpectedOutput

msgOutput: DB 13,10,"Output: ",13,10
    msgOutputSz EQU $-msgOutput

msgLoss: DB 13,10,"Loss: "
    msgLossSz EQU $-msgLoss

msgWeights: DB 13,10,"Weights: ",13,10
    msgWeightsSz EQU $-msgWeights

msgEpoch: DB 13,10,"Epoch: "
    msgEpochSz EQU $-msgEpoch

in_data:
	;  X1   X2  |  BIAS
	DD 0.0, 0.0 , 1.0
	DD 0.0, 1.0 , 1.0
	DD 1.0, 0.0 , 1.0
	DD 1.0, 1.0 , 1.0
    in_size EQU ($-in_data)/4
    in_rows EQU 4
    in_cols EQU 3
    in_line_size EQU in_cols*4

expected_data:
	;   0    1
	DD 1.0, 0.0
	DD 0.0, 1.0
	DD 0.0, 1.0
	DD 0.0, 1.0
    expected_size EQU ($-expected_data)/4
    expected_rows EQU 4
    expected_cols EQU 2
    expected_line_size EQU expected_cols*4

out_data: DD expected_cols dup(0)
    out_size EQU ($-out_data)/4

weights_data:
    DD 6 dup(0)
    weights_size EQU ($-weights_data)/4
    weights_rows EQU 2
    weights_cols EQU 3

f32buff: DB "XXXXXXXXXXXXXXXXXXXXX",13,10
    f32buffSz EQU $-f32buff

uint32buff: DB "XXXXXXXXXX",13,10
    uint32buffSz EQU $-uint32buff
