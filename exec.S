/* struct token {
 *     int numline;      0(%reg)
 *     int lineoffset;   4(%reg)
 *     int aux;          8(%reg)
 *     char type;        12(%reg)
 * }
 */

#include "global.inc"

.section .bss
	TOKENS: .zero GLOBL_TOTAL_TOKENS * GLOBL_TOKEN_SIZE

	.globl TOKENS
