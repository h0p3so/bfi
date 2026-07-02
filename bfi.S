#define STDIN_FD           0
#define STDOUT_FD          1
#define STDERR_FD          2

#define FATAL_USAGE_STATUS 1

.section .rodata
	.usage_msg: .string "$ bfi [filename] [opts: O (optimize) | W (wrap memory) | H (help)]\n"
	.usage_len: .quad   67

.section .text
.globl _start

.macro DISPLAY fd, msg, len
	movq	$1, %rax
	movq	$2, %rdi
	leaq	\msg, %rsi
	movq	\len, %rdx
	syscall
.endm

.macro EXIT status
	movq	$60, %rax
	movq	$\status, %rdi
	syscall
.endm


_start:
	movq	(%rsp), %rax
	cmpq	$1, %rax
	je	._usage
	cmpq	$2, %rax
	je	._go

._go:
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
._usage:
	DISPLAY STDERR_FD, .usage_msg(%rip), .usage_len(%rip)
	EXIT FATAL_USAGE_STATUS

