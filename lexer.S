#define LEXER_OFFSET_SRC          -8
#define LEXER_OFFSET_SRC_LENGTH  -16
#define LEXER_OFFSET_COUNT       -24
#define LEXER_OFFSET_NUMLINE     -28
#define LEXER_OFFSET_LINEOFFSET  -32
#define LEXER_OFFSET_CUR_TOKEN   -40
#define LEXER_OFFSET_TOKEN_COUNT -48

#define LEXER_PAIR_NOT_FOUND     -1

.section .rodata
	.fatal_overflow_msg: .string "bfi:lexer: max token capacity reached\n"
	.fatal_overflow_len: .quad   38

#include "global.inc"

.section .text

.globl lexer
lexer:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$48, %rsp
	movq	%rdi, LEXER_OFFSET_SRC(%rbp)
	movq	%rsi, LEXER_OFFSET_SRC_LENGTH(%rbp)
	movq	$0, LEXER_OFFSET_COUNT(%rbp)
	movl	$1, LEXER_OFFSET_NUMLINE(%rbp)
	movl	$0, LEXER_OFFSET_LINEOFFSET(%rbp)
	#
	# tokens
	#
	leaq	TOKENS(%rip), %rax
	movq	%rax, LEXER_OFFSET_CUR_TOKEN(%rbp)
	movq	$0, LEXER_OFFSET_TOKEN_COUNT(%rbp)
.loop:
	cmpq	LEXER_OFFSET_TOKEN_COUNT(%rbp), %rax
	cmpq	$GLOBL_TOTAL_TOKENS, %rax
	jae	._fatal_tokensoverflow
	#
	movq	LEXER_OFFSET_COUNT(%rbp), %rax
	cmpq	LEXER_OFFSET_SRC_LENGTH(%rbp), %rax
	jae	.fini
	#
	# read and increment line's offset
	#
	movq	LEXER_OFFSET_SRC(%rbp), %rdi
	movzbl	(%rdi, %rax), %edi
	#
	# look out for tokens
	#
	cmpb	$'\n', %dil
	je	.loop_newline	
	call	._is_token
	testq	%rax, %rax
	jz	.loop_advance
	# setting meta data --------------------------------#
	movl	LEXER_OFFSET_NUMLINE(%rbp), %r8d            #
	movl	LEXER_OFFSET_LINEOFFSET(%rbp), %r9d         #
	movq	LEXER_OFFSET_CUR_TOKEN(%rbp), %rax          #
	movl	%r8d, GLOBL_TOK_OFF_NUMLINE(%rax)           #
	movl	%r9d, GLOBL_TOK_OFF_LINEOFF(%rax)           #
	movl	$0,   GLOBL_TOK_OFF_AUX(%rax)               #
	movb	%dil, GLOBL_TOK_OFF_TYPE(%rax)              #
	# --------------------------------------------------#
	cmpb	$GLOBL_TOKEN_LEF, %dil
	je	.loop_mark_and_continue
	cmpb	$GLOBL_TOKEN_RIG, %dil
	je	.loop_pair_right_brace

	jmp	.loop_next_token


.loop_pair_right_brace:
	# TODO
	jmp	.loop_next_token
.loop_mark_and_continue:
	movl	$LEXER_PAIR_NOT_FOUND, GLOBL_TOK_OFF_AUX(%rax)
	jmp	.loop_next_token
.loop_next_token:
	incq	LEXER_OFFSET_TOKEN_COUNT(%rbp)
	movq	LEXER_OFFSET_TOKEN_COUNT(%rbp), %rax
	movq	$GLOBL_TOKEN_SIZE, %rbx
	mulq	%rbx
	movq	%rax, %rcx
	leaq	TOKENS(%rip), %rax
	addq	%rcx, %rax
	movq	%rax, LEXER_OFFSET_CUR_TOKEN(%rbp)
	jmp	.loop_advance
.loop_newline:
	incl	LEXER_OFFSET_NUMLINE(%rbp)
	movq	$0, LEXER_OFFSET_LINEOFFSET(%rbp)
	jmp	.loop_advance
.loop_advance:
	incl	LEXER_OFFSET_LINEOFFSET(%rbp)
	incq	LEXER_OFFSET_COUNT(%rbp)
	jmp	.loop
.fini:
	leave
	ret
._fatal_tokensoverflow:
	DISPLAY STDERR_FD, .fatal_overflow_msg(%rip), .fatal_overflow_len(%rip)
	EXIT EXIT_STATUS_OVERFLOW

._is_token:
	movq	$1, %rax
	cmpb	$GLOBL_TOKEN_ADD, %dil 
	je	._is_token_fini
	cmpb	$GLOBL_TOKEN_SUB, %dil
	je	._is_token_fini
	cmpb	$GLOBL_TOKEN_OUT, %dil
	je	._is_token_fini
	cmpb	$GLOBL_TOKEN_INP, %dil
	je	._is_token_fini
	cmpb	$GLOBL_TOKEN_LEF, %dil
	je	._is_token_fini
	cmpb	$GLOBL_TOKEN_RIG, %dil
	je	._is_token_fini
	cmpb	$GLOBL_TOKEN_NXT, %dil
	je	._is_token_fini
	cmpb	$GLOBL_TOKEN_PRV, %dil
	je	._is_token_fini
	xorq	%rax, %rax
._is_token_fini:
	ret
