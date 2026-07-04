#define MAIN_OFFSET_S_FLAG        -2
#define MAIN_OFFSET_W_FLAG        -4
#define MAIN_OFFSET_I_FLAG        -6
#define MAIN_OFFSET_FILENAME     -14
#define MAIN_OFFSET_FILE_FD      -18
#define MAIN_OFFSET_FILE_SZ      -26
#define MAIN_OFFSET_BF_SRC       -34
#define MAIN_OFFSET_NUM_TOKENS   -42

#define FLAG_SAFE                'S'
#define FLAG_WRAP                'W'
#define FLAG_INFO                'I'

#define FLAG_SET                 1

.section .rodata
	.usage_msg: .string "$ bfi [empty] | <filename> [exclusive opts: W (wrap memory) | I (info) | S (safe)\n"
	.usage_len: .quad   82

	.fatal_bad_file_msg: .string "bfi: file provided does not exist\n"
	.fatal_bad_file_len: .quad   34

	.fatal_bad_memo_msg: .string "bfi: cannot allocate space\n"
	.fatal_bad_memo_len: .quad   27

	.fatal_bad_read_msg: .string "bfi: error while reading\n"
	.fatal_bad_read_len: .quad   25

.section .text
.globl _start

#include "global.inc"

_start:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$48, %rsp
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
	#
	cmpb	$FLAG_WRAP, %dil
	je	.cli_parsing_W
	cmpb	$FLAG_INFO, %dil
	je	.cli_parsing_I
	cmpb	$FLAG_SAFE, %dil
	je	.cli_parsing_S
	#
	jmp	.cli_parsing_loop
.cli_parsing_W:
	movw	$FLAG_SET, MAIN_OFFSET_W_FLAG(%rbp)
	jmp	.cli_parsing_loop
.cli_parsing_I:
	movw	$FLAG_SET, MAIN_OFFSET_I_FLAG(%rbp)
	jmp	.cli_parsing_loop
.cli_parsing_S:
	movw	$FLAG_SET, MAIN_OFFSET_S_FLAG(%rbp)
	jmp	.cli_parsing_loop
.cli_parsing_loop:
	incq	%r8
	jmp	.cli_parsing
.init:
	movq	24(%rbp), %rax
	movq	%rax, MAIN_OFFSET_FILENAME(%rbp)
.read_file:
	#
	# access syscall
	#
	movq	MAIN_OFFSET_FILENAME(%rbp), %rdi
	xorq	%rsi, %rsi
	movq	$21, %rax
	syscall
	testq	%rax, %rax
	jnz	._fatal_bad_file
	#
	# open syscall
	#
	movq	MAIN_OFFSET_FILENAME(%rbp), %rdi
	xorq	%rsi, %rsi
	movq	$2, %rax
	syscall
	movl	%eax, MAIN_OFFSET_FILE_FD(%rbp)
	#
	# lseek syscall: getting file's size
	#
	movl	MAIN_OFFSET_FILE_FD(%rbp), %edi
	xorq	%rsi, %rsi
	movq	$2, %rdx
	movq	$8, %rax
	syscall
	movq	%rax, MAIN_OFFSET_FILE_SZ(%rbp)
	#
	movl	MAIN_OFFSET_FILE_FD(%rbp), %edi
	xorq	%rsi, %rsi
	xorq	%rdx, %rdx
	movq	$8, %rax
	syscall
	#
	# nmap syscall: allocating file content
	#
	xorq	%rdi, %rdi
	movq	MAIN_OFFSET_FILE_SZ(%rbp), %rsi
	movq	$1, %rsi
	movq	$3, %rdx
	movq	$34, %r10
	movq	$-1, %r8
	xorq	%r9, %r9
	movq	$9, %rax
	syscall
	cmpq	$-1, %rax
	je	._fatal_bad_memo
	movq	%rax, MAIN_OFFSET_BF_SRC(%rbp)
	#
	# read syscall
	#
	movl	MAIN_OFFSET_FILE_FD(%rbp), %edi
	movq	MAIN_OFFSET_BF_SRC(%rbp), %rsi
	movq	MAIN_OFFSET_FILE_SZ(%rbp), %rdx
	xorq	%rax, %rax
	syscall
	cmpq	$-1, %rax
	je	._fatal_bad_read
	#
	# close syscall
	#
	movl	MAIN_OFFSET_FILE_FD(%rbp), %edi
	movq	$3, %rax
	syscall
.callexer:
	movq	MAIN_OFFSET_BF_SRC(%rbp), %rdi
	movq	MAIN_OFFSET_FILE_SZ(%rbp), %rsi
	call	lexer
	movq	%rax, MAIN_OFFSET_NUM_TOKENS(%rbp)
	#
	xorq	%rax, %rax
	movw	MAIN_OFFSET_I_FLAG(%rbp), %ax
	cmpw	$FLAG_SET, %ax
	jne	.callexec
	#
	movq	MAIN_OFFSET_NUM_TOKENS(%rbp), %rdi
	movq	MAIN_OFFSET_FILENAME(%rbp), %rsi
	call	info
.callexec:

._fini:
	#
	# unmap syscall
	#
	leaq	MAIN_OFFSET_BF_SRC(%rbp), %rdi
	movq	MAIN_OFFSET_FILE_SZ(%rbp), %rsi
	movq	$11, %rax
	syscall
	#
	movq	$60, %rax
	movq	$0, %rdi
	syscall
._usage:
	DISPLAY STDOUT_FD, .usage_msg(%rip), .usage_len(%rip)
	EXIT EXIT_STATUS_OK
._fatal_bad_file:
	DISPLAY STDERR_FD, .fatal_bad_file_msg(%rip), .fatal_bad_file_len(%rip)
	EXIT EXIT_STATUS_BAD_FILE
._fatal_bad_memo:
	DISPLAY STDERR_FD, .fatal_bad_memo_msg(%rip), .fatal_bad_memo_len(%rip)
	EXIT EXIT_STATUS_BAD_MEMO
._fatal_bad_read:
	DISPLAY STDERR_FD, .fatal_bad_read_msg(%rip), .fatal_bad_read_len(%rip)
	EXIT EXIT_STATUS_BAD_READ
