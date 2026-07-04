#define EXEC_MEM_LENGTH 30000

#define EXEC_OFFSET_MAX_TOKENS  -8
#define EXEC_OFFSET_SAFE_FLAG   -10
#define EXEC_OFFSET_CUR_TOKEN   -18

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
# rsi: is safe set?
#
# note: r8 register acts like the memory pointer
#       r9 stores the current token
#       r10: works as a counter for .out and .inp labels (also safe ones)
exec:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$32, %rsp
	movq	%rdi, EXEC_OFFSET_MAX_TOKENS(%rbp)
	movw	%si, EXEC_OFFSET_SAFE_FLAG(%rbp)
	movq	$0, EXEC_OFFSET_CUR_TOKEN(%rbp)
	leaq	.memory(%rip), %r8
	#
	cmpw	$GLOBL_FLAG_SET, %si
	je	.safe_loop
	#
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
	ja	.next
	movl	GLOBL_TOK_OFF_AUX(%r8), %eax
	cltq
	movq	%rax, EXEC_OFFSET_CUR_TOKEN(%rbp)
	jmp	.next
.rig:
	xorq	%rax, %rax
	movb	(%r8), %al
	cmpb	$0, %al
	jbe	.next
	movl	GLOBL_TOK_OFF_AUX(%r8), %eax
	cltq
	movq	%rax, EXEC_OFFSET_CUR_TOKEN(%rbp)
	jmp	.next
.nxt:
	movl	GLOBL_TOK_OFF_AUX(%r9), %ebx
	addq	%rbx, %r8
	jmp	.next
.prv:
	movl	GLOBL_TOK_OFF_AUX(%r9), %ebx
	subq	%rbx, %r8
	jmp	.next
.next:
	xorq	%r10, %r10
	incq	EXEC_OFFSET_CUR_TOKEN(%rbp)
	jmp	.loop
#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
.safe_loop:
	movq	EXEC_OFFSET_CUR_TOKEN(%rbp), %rdi
	cmpq	EXEC_OFFSET_MAX_TOKENS(%rbp), %rdi
	jae	.fini
	GET_TOKEN
	xorq	%rdi, %rdi
	movb	GLOBL_TOK_OFF_TYPE(%rax), %dil
	#
	cmpb	$GLOBL_TOKEN_ADD, %dil
	je	.safe_add
	cmpb	$GLOBL_TOKEN_SUB, %dil
	je	.safe_sub
	cmpb	$GLOBL_TOKEN_OUT, %dil
	je	.safe_out
	cmpb	$GLOBL_TOKEN_INP, %dil
	je	.safe_inp
	cmpb	$GLOBL_TOKEN_LEF, %dil
	je	.safe_lef
	cmpb	$GLOBL_TOKEN_RIG, %dil
	je	.safe_rig
	cmpb	$GLOBL_TOKEN_NXT, %dil
	je	.safe_nxt
	cmpb	$GLOBL_TOKEN_PRV, %dil
	je	.safe_prv
	#
	jmp	._fatal_unreachable
.safe_add:
.safe_sub:
.safe_out:
.safe_inp:
.safe_lef:
.safe_rig:
.safe_nxt:
.safe_prv:
#   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-.   .-.-
#  / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \ \ / / \
# `-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'   `-`-'
.fini:
	leave
	ret
._fatal_unreachable:
	DISPLAY STDERR_FD, .fatal_unreachable_msg(%rip), .fatal_unreachable_len(%rip)
	EXIT EXIT_STATUS_UNREACHA
