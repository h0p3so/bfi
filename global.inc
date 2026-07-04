#define STDIN_FD  0
#define STDOUT_FD 1
#define STDERR_FD 2

#define EXIT_STATUS_OK       0
#define EXIT_STATUS_BAD_FILE 1
#define EXIT_STATUS_BAD_MEMO 2
#define EXIT_STATUS_BAD_READ 3
#define EXIT_STATUS_T_OVERFL 4
#define EXIT_STATUS_S_OVERFL 5
#define EXIT_STATUS_UNOPENED 6

#define GLOBL_TOKEN_ADD '+'
#define GLOBL_TOKEN_SUB '-'
#define GLOBL_TOKEN_OUT '.'
#define GLOBL_TOKEN_INP ','
#define GLOBL_TOKEN_LEF '['
#define GLOBL_TOKEN_RIG ']'
#define GLOBL_TOKEN_NXT '>'
#define GLOBL_TOKEN_PRV '<'

#define GLOBL_TOK_OFF_NUMLINE 0
#define GLOBL_TOK_OFF_LINEOFF 4
#define GLOBL_TOK_OFF_AUX     8
#define GLOBL_TOK_OFF_TYPE    12

#define GLOBL_TOTAL_TOKENS 1024
#define GLOBL_TOKEN_SIZE   18

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

# ---------------------------------
# gets the token at `rdi` position
# sets the token in rax
# ---------------------------------
.macro GET_TOKEN
	movq	%rdi, %rax
	movq	$GLOBL_TOKEN_SIZE, %rbx
	mulq	%rbx
	movq	%rax, %rcx
	leaq	TOKENS(%rip), %rax
	addq	%rcx, %rax
.endm

