#define EXEC_TOTAL_TOKENS 1024
#define EXEC_TOKEN_SIZE   18

/* struct token {
 *     int numline;      0(%reg)
 *     int lineoffset;   4(%reg)
 *     int aux;          8(%reg)
 *     char type;        12(%reg)
 * }
 */

.section .bss
	TOKENS: .zero EXEC_TOTAL_TOKENS * EXEC_TOKEN_SIZE

	.globl TOKENS
