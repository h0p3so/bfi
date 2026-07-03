#define LEXER_OFFSET_SRC          -8
#define LEXER_OFFSET_SRC_LENGTH  -16
#define LEXER_OFFSET_COUNT       -24
#define LEXER_OFFSET_NUMLINE     -28
#define LEXER_OFFSET_LINEOFFSET  -32
#define LEXER_OFFSET_CUR_TOKEN   -40
#define LEXER_OFFSET_TOKEN_COUNT -48

#define LEXER_PAIR_NOT_FOUND     -1

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
	movq	$1, LEXER_OFFSET_NUMLINE(%rbp)
	movq	$0, LEXER_OFFSET_LINEOFFSET(%rbp)
	#
	# tokens
	#
	leaq	TOKENS(%rip), %rax
	movq	%rax, LEXER_OFFSET_CUR_TOKEN(%rbp)
	movq	$0, LEXER_OFFSET_TOKEN_COUNT(%rbp)
.loop:
	movq	LEXER_OFFSET_COUNT(%rbp), %rax
	cmpq	LEXER_OFFSET_SRC_LENGTH(%rbp), %rax
	jae	.fini
	#
	# read and increment line's offset
	#
	movq	LEXER_OFFSET_SRC(%rbp), %rdi
	movzbl	(%rdi, %rax), %edi
	incl	LEXER_OFFSET_LINEOFFSET(%rbp)
	#
	# look out for tokens
	#
	cmpb	$'\n', %dil
	je	.loop_newline	
	call	._is_token
	testq	%rax, %rax
	jz	.loop_next
	# setting meta data --------------------------------#
	movl	LEXER_OFFSET_NUMLINE(%rbp), %r8d            #
	movl	LEXER_OFFSET_LINEOFFSET(%rbp), %r9d         #
	movq	LEXER_OFFSET_CUR_TOKEN(%rbp), %rax          #
	movl	%r8d, GLOBL_TOK_OFF_NUMLINE(%rax)           #
	movl	%r9d, GLOBL_TOK_OFF_LINEOFF(%rax)           #
	movl	$0,   GLOBL_TOK_OFF_LINEOFF(%rax)           #
	movb	%dil, GLOBL_TOK_OFF_TYPE(%rax)              #
	# --------------------------------------------------#
	cmpb	$GLOBL_TOKEN_LEF, %dil
	je	.loop_mark_and_continue
	cmpb	$GLOBL_TOKEN_RIG, %dil
	je	.loop_pair_right_brace

	jmp	.loop_next
.loop_pair_right_brace:
	
.loop_mark_and_continue:
	movl	$LEXER_PAIR_NOT_FOUND, GLOBL_TOK_OFF_LINEOFF(%rax)
	jmp	.loop_next
.loop_newline:
	incl	LEXER_OFFSET_NUMLINE(%rbp)
	movq	$0, LEXER_OFFSET_LINEOFFSET(%rbp)
	jmp	.loop_next
.loop_next:
	incq	LEXER_OFFSET_COUNT(%rbp)
	jmp	.loop
.fini:
	leave
	ret


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
