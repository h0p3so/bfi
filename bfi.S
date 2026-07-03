#define STDIN_FD             0
#define STDOUT_FD            1
#define STDERR_FD            2

#define EXIT_STATUS_USAGE    0

#define MAIN_OFFSET_O_FLAG   -2
#define MAIN_OFFSET_W_FLAG   -4

#define FLAG_HELP            'H'
#define FLAG_OPTIMIZE        'O'
#define FLAG_WRAP            'W'

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
	# stack frame ----------------------
	# -2(%rip): MAIN_OFFSET_O_FLAG
	# -4(%rip): MAIN_OFFSET_O_FLAG
	#
	#
	#
	#
	#
	#
	#
	#
	#
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$16, %rsp
	#
	# checking usage
	#
	movq	8(%rbp), %rcx
	cmpq	$1, %rcx
	je	._usage
	cmpq	$2, %rcx
	je	.init
	movq	$2, %r8
.cli_parsing:
	cmpq	%rcx, %r8
	jae	.init
	movq	16(%rbp, %r8, 8), %rax
	movzbl	(%rax), %edi
	cmpb	$FLAG_HELP, %dil
	je	._usage
	cmpb	$FLAG_OPTIMIZE, %dil
	je	.cli_parsing_O
	cmpb	$FLAG_WRAP, %dil
	je	.cli_parsing_W
	jmp	.cli_parsing_loop
.cli_parsing_O:
	movw	$1, MAIN_OFFSET_O_FLAG(%rbp)
	jmp	.cli_parsing_loop
.cli_parsing_W:	
	movw	$1, MAIN_OFFSET_W_FLAG(%rbp)
	jmp	.cli_parsing_loop
.cli_parsing_loop:
	incq	%r8
	jmp	.cli_parsing
.init:

._fini:
	movq	$60, %rax
	movq	$0, %rdi
	syscall
._usage:
	DISPLAY STDERR_FD, .usage_msg(%rip), .usage_len(%rip)
	EXIT EXIT_STATUS_USAGE
