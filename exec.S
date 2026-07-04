#define EXEC_MEM_LENGTH 30000

#include "global.inc"

.section .bss
	TOKENS: .zero GLOBL_TOTAL_TOKENS * GLOBL_TOKEN_SIZE
	.globl TOKENS

	.memory: .zero EXEC_MEM_LENGTH

.section .text
.globl exec

# rdi: number of tokens
# rsi: 
exec:
	pushq	%rbp
	movq	%rsp, %rbp

	leave
	ret
