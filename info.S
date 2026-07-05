#define INFO_OFFSET_TOK_MAX   -8
#define INFO_OFFSET_FILENAME  -16
#define INFO_OFFSET_TOK_COUNT -24

.section .rodata
	.info_fmt: .string "bfi: `%s` source code\n"
	.info_token_fmt: .string "%>10d token: <%c:%>4d>\n"

	.msg: .string "hola\n"
	.len: .quad 5

.section .text

#include "global.inc"

.globl info

# rdi: number of tokens
# rsi: source code filename
#
# exists the program
info:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp
	movq	%rdi, INFO_OFFSET_TOK_MAX(%rbp)
	movq	%rsi, INFO_OFFSET_FILENAME(%rbp)
	movq	$0, INFO_OFFSET_TOK_COUNT(%rbp)
	#
	movq	$STDOUT_FD, %rdi
	leaq	.info_fmt(%rip), %rsi
	movq	INFO_OFFSET_FILENAME(%rbp), %rax
	pushq	%rax
	call	tiny_pf
	addq	$8, %rsp
.loop:
	movq	INFO_OFFSET_TOK_COUNT(%rbp), %rdi
	cmpq	INFO_OFFSET_TOK_MAX(%rbp), %rdi
	jae	.fini
	GET_TOKEN
	xorq	%rcx, %rcx
	movl	GLOBL_TOK_OFF_AUX(%rax), %ecx
	pushq	%rcx
	movb	GLOBL_TOK_OFF_TYPE(%rax), %cl
	pushq	%rcx
	pushq	%rdi
	movq	$STDOUT_FD, %rdi
	leaq	.info_token_fmt(%rip), %rsi
	call	tiny_pf
	addq	$16, %rsp
	incq	INFO_OFFSET_TOK_COUNT(%rbp)
	jmp	.loop
.fini:
	EXIT EXIT_STATUS_OK
