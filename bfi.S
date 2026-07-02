#define FATAL_USAGE_STATUS 1

.section .rodata
	.fatal_usage_msg: .string "bfi: bad usage\n"
	.fatal_usage_len: .quad    15

.section .text
.globl _start

.macro error msg, len, status
	movq	$1, %rax
	movq	$2, %rdi
	leaq	\msg, %rsi
	movq	\len, %rdx
	syscall
	movq	$60, %rax
	movq	$\status, %rdi
	syscall
.endm

_start:
	movq	(%rsp), %rax
	cmpq	$1, %rax
	je	._fatal_bad_usage	
	# stack frame ----------------------
	#
	#
	#
	#
	#
	#
	#
	#
	#
	#
._fini:
	movq	$60, %rax
	movq	$60, %rdi
	syscall
._fatal_bad_usage:
	error	.fatal_usage_msg(%rip), .fatal_usage_len(%rip), FATAL_USAGE_STATUS
