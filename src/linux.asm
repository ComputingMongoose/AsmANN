%use masm
section .text
global osInit
global osConsoleWrite
global osExit

; Initialization of OS related functionality
; Input: None
; Output: None
osInit:
	RET

; Write a message to console
; Input: 
;     RSI - Message
;     RDX - Length
osConsoleWrite:
	PUSH rdi
	PUSH rax
	PUSH rbx
	PUSH rcx
	PUSH rdx
	
	MOV rdi, 1	; file handle 1=STDOUT
	MOV rax, 1	; syscall 1=write
	SYSCALL
	
	POP rdx
	POP rcx
	POP rbx
	POP rax
	POP rdi
	RET

; Exits back to the operating system
osExit:
	XOR rdi,rdi     ; exit code
	MOV rax,60      ; syscall 60=exit
	SYSCALL
	RET             ; this will never execute, after the syscall the program is ended
