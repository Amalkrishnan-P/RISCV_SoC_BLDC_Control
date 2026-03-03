/* 
   Startup sequence for C. Not clearing bss.
*/

.text
.global _start
_start:
	li x2, 8192
	call main
