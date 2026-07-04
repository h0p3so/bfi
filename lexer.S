#define LEXER_OFFSET_SRC             -8
#define LEXER_OFFSET_SRC_LENGTH     -16
#define LEXER_OFFSET_COUNT          -24
#define LEXER_OFFSET_NUMLINE        -28
#define LEXER_OFFSET_LINEOFFSET     -32
#define LEXER_OFFSET_CUR_TOKEN      -40
#define LEXER_OFFSET_TOKEN_COUNT    -48
#define LEXER_OFFSET_LAST_TYPE_SEEN -50
#define LEXER_OFFSET_STACK_COUNT    -58

#define LEXER_INDEX_STACK_CAP       256
#define LEXER_INDEX_STACK_MEMB_SZ   8

.section .bss
	.index_stack: .zero LEXER_INDEX_STACK_CAP * LEXER_INDEX_STACK_MEMB_SZ

.section .rodata
	.fatal_tok_ovrflw_msg: .string "bfi:lexer: max token capacity reached\n"
	.fatal_tok_ovrflw_len: .quad   38

	.fatal_stk_ovrflw_msg: .string "bfi:lexer: max stack capacity reached\n"
	.fatal_stk_ovrflw_len: .quad   38

	.fatal_unopened_fmt: .string "bfi:lexer: cannot pair `]` (at %>3d:%d)\n"

#include "global.inc"

.section .text

.macro advance_next_token
	incq	LEXER_OFFSET_TOKEN_COUNT(%rbp)
	movq	LEXER_OFFSET_TOKEN_COUNT(%rbp), %rax
	movq	$GLOBL_TOKEN_SIZE, %rbx
	mulq	%rbx
	movq	%rax, %rcx
	leaq	TOKENS(%rip), %rax
	addq	%rcx, %rax
	movq	%rax, LEXER_OFFSET_CUR_TOKEN(%rbp)
.endm

# ----------------------------------
# rdi: source code
# rsi: source code length
#
# rax: number of tokens generated
# ----------------------------------
.globl lexer
lexer:
	pushq	%rbp
	movq	%rsp, %rbp
	subq	$64, %rsp
	movq	%rdi, LEXER_OFFSET_SRC(%rbp)
	movq	%rsi, LEXER_OFFSET_SRC_LENGTH(%rbp)
	movq	$0, LEXER_OFFSET_COUNT(%rbp)
	movl	$1, LEXER_OFFSET_NUMLINE(%rbp)
	movl	$0, LEXER_OFFSET_LINEOFFSET(%rbp)
	movq	$0, LEXER_OFFSET_STACK_COUNT(%rbp)
	#
	# tokens
	#
	leaq	TOKENS(%rip), %rax
	movq	%rax, LEXER_OFFSET_CUR_TOKEN(%rbp)
	movq	$0, LEXER_OFFSET_TOKEN_COUNT(%rbp)
.loop:
	movq	LEXER_OFFSET_TOKEN_COUNT(%rbp), %rax
	cmpq	$GLOBL_TOTAL_TOKENS, %rax
	jae	._fatal_tokensovrflw
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
	jmp	.loop_optmz
.loop_pair_right_brace:
	movq	LEXER_OFFSET_STACK_COUNT(%rbp), %rcx
	cmpq	$0, %rcx
	je	._fatal_unopened
	#
	# getting index of `[` pair token
	#
	leaq	.index_stack(%rip), %rax
	movq	(%rax, %rcx, 8), %rdi
	get_token
	#
	# r8 will contain the index of `[` token within the
	# token array, and the current index will be set to
	# `[` to pair it with the current `]`
	#
	movl	GLOBL_TOK_OFF_AUX(%rax), %r8d
	movq	LEXER_OFFSET_STACK_COUNT(%rbp), %rdi
	movl	%edi, GLOBL_TOK_OFF_AUX(%rax)
	#
	get_token
	#
	# pairing `]` with `[`
	#
	movl	%r8d, GLOBL_TOK_OFF_AUX(%rax)
	#
	decq	LEXER_OFFSET_STACK_COUNT(%rbp)
	jmp	.loop_next_token
.loop_mark_and_continue:
	movq	LEXER_OFFSET_STACK_COUNT(%rbp), %rcx
	cmpq	$LEXER_INDEX_STACK_CAP, %rcx
	jae	._fatal_stackovrflw
	#
	# aux will temporarily store its own index within the
	# token array so when `]` is found they can exchange indexes
	#
	movl	%ecx, GLOBL_TOK_OFF_AUX(%rax)
	#
	leaq	.index_stack(%rip), %rax
	movq	%rcx, (%rax, %rcx, 8)
	incq	LEXER_OFFSET_STACK_COUNT(%rbp)
	jmp	.loop_next_token
.loop_optmz:
	cmpb	LEXER_OFFSET_LAST_TYPE_SEEN(%rbp), %dil
	jne	.loop_next_token
	incl	GLOBL_TOK_OFF_AUX(%rax)
	jmp	.loop_advance
.loop_next_token:
	advance_next_token
	jmp	.loop_advance
.loop_newline:
	incl	LEXER_OFFSET_NUMLINE(%rbp)
	movl	$-1, LEXER_OFFSET_LINEOFFSET(%rbp)
	jmp	.loop_advance
.loop_advance:
	incl	LEXER_OFFSET_LINEOFFSET(%rbp)
	incq	LEXER_OFFSET_COUNT(%rbp)
	jmp	.loop
.fini:
	movq	LEXER_OFFSET_TOKEN_COUNT(%rbp), %rax
	leave
	ret
._fatal_tokensovrflw:
	DISPLAY STDERR_FD, .fatal_tok_ovrflw_msg(%rip), .fatal_tok_ovrflw_len(%rip)
	EXIT EXIT_STATUS_T_OVERFL
._fatal_stackovrflw:
	DISPLAY STDERR_FD, .fatal_stk_ovrflw_msg(%rip), .fatal_stk_ovrflw_len(%rip)
	EXIT EXIT_STATUS_S_OVERFL
._fatal_unopened:
	movq	$STDERR_FD, %rdi
	leaq	.fatal_unopened_fmt(%rip), %rsi
	#
	xorq	%rcx, %rcx
	movl	GLOBL_TOK_OFF_LINEOFF(%rax), %ecx
	pushq	%rcx
	movl	GLOBL_TOK_OFF_NUMLINE(%rax), %ecx
	pushq	%rcx
	#
	call	tiny_pf
	addq	$16, %rsp
	EXIT EXIT_STATUS_UNOPENED

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
