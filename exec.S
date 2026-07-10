#define EXEC_MEM_LENGTH 30'000

#define EXEC_OFFSET_MAX_TOKENS  -8
#define EXEC_OFFSET_CUR_TOKEN   -16

#include "global.inc"

.section .rodata
	.fatal_unreachable_msg: .string "bfi:exec: unreachable, please report!\n"
	.fatal_unreachable_len: .quad   38

.section .bss
	TOKENS: .zero GLOBL_TOTAL_TOKENS * GLOBL_TOKEN_SIZE
	.globl TOKENS

	.memory: .zero EXEC_MEM_LENGTH

.section .text
.globl exec

# rdi: number of tokens
#
# note: r8 register acts like the memory pointer
#       r9 stores the current token
#       r10: works as a counter for .out and .inp labels
exec:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp
	movq	%rdi, EXEC_OFFSET_MAX_TOKENS(%rbp)
	movq	$0, EXEC_OFFSET_CUR_TOKEN(%rbp)
	leaq	.memory(%rip), %r8
	xorq	%r10, %r10
#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
.loop:
	movq	EXEC_OFFSET_CUR_TOKEN(%rbp), %rdi
	cmpq	EXEC_OFFSET_MAX_TOKENS(%rbp), %rdi
	jae	.fini
	GET_TOKEN
	movq	%rax, %r9
	xorq	%rdi, %rdi
	movb	GLOBL_TOK_OFF_TYPE(%r9), %dil
	#
	cmpb	$GLOBL_TOKEN_ADD, %dil
	je	.add
	cmpb	$GLOBL_TOKEN_SUB, %dil
	je	.sub
	cmpb	$GLOBL_TOKEN_OUT, %dil
	je	.out
	cmpb	$GLOBL_TOKEN_INP, %dil
	je	.inp
	cmpb	$GLOBL_TOKEN_LEF, %dil
	je	.lef
	cmpb	$GLOBL_TOKEN_RIG, %dil
	je	.rig
	cmpb	$GLOBL_TOKEN_NXT, %dil
	je	.nxt
	cmpb	$GLOBL_TOKEN_PRV, %dil
	je	.prv
	#
	jmp	._fatal_unreachable
.add:
	movl	GLOBL_TOK_OFF_AUX(%r9), %ebx
	addb	%bl, (%r8)
	jmp	.next
.sub:
	movl	GLOBL_TOK_OFF_AUX(%r9), %ebx
	subb	%bl, (%r8)
	jmp	.next
.out:
	movl	GLOBL_TOK_OFF_AUX(%r9), %eax
	cmpl	%eax, %r10d
	jae	.next
	movq	$1, %rax
	movq	$1, %rdi
	movq	%r8, %rsi
	movq	$1, %rdx
	syscall
	incl	%r10d
	jmp	.out
.inp:
	movl	GLOBL_TOK_OFF_AUX(%r9), %eax
	cmpl	%eax, %r10d
	jae	.next
	movq	$0, %rax
	movq	$1, %rdi
	movq	%r8, %rsi
	movq	$1, %rdx
	syscall
	incl	%r10d
	jmp	.out
.lef:
	xorq	%rax, %rax
	movb	(%r8), %al
	cmpb	$0, %al
	jne	.next
	movl	GLOBL_TOK_OFF_AUX(%r9), %eax
	cltq
	movq	%rax, EXEC_OFFSET_CUR_TOKEN(%rbp)
	jmp	.next
.rig:
	xorq	%rax, %rax
	movb	(%r8), %al
	cmpb	$0, %al
	je	.next
	movl	GLOBL_TOK_OFF_AUX(%r9), %eax
	cltq
	movq	%rax, EXEC_OFFSET_CUR_TOKEN(%rbp)
	jmp	.next
.nxt:
	movl	GLOBL_TOK_OFF_AUX(%r9), %r10d
	addq	%r10, %r8
	jmp	.next
.prv:
	movl	GLOBL_TOK_OFF_AUX(%r9), %r10d
	subq	%r10, %r8
	jmp	.next
.next:
	xorq	%r10, %r10
	incq	EXEC_OFFSET_CUR_TOKEN(%rbp)
	jmp	.loop
.fini:
	leave
	ret
._fatal_unreachable:
	DISPLAY STDERR_FD, .fatal_unreachable_msg(%rip), .fatal_unreachable_len(%rip)
	EXIT EXIT_STATUS_UNREACHA
