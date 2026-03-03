/* 
UART Functions
*/

#include "uart.h"

#define UART_DIV ((volatile unsigned char *) 0x80000008)
#define UART_DATA ((volatile unsigned char *) 0x8000000c)

void uart_set_div(unsigned int div)
{
  volatile int delay;

  *UART_DIV = div;

  /* Need to delay a little */
  for (delay = 0; delay < 200; delay++) {}
}

void uart_print_hex(unsigned int val)
{
  char ch;
  int i;

  for (i = 0; i < 8; i++) {
    ch = (val & 0xf0000000) >> 28;
    *UART_DATA = "0123456789abcdef"[ch];
    val = val << 4;
  }
}
void uart_print_dec(unsigned int val)
{
    char buf[10];   // max 10 digits for 32-bit unsigned int
    int i = 0;

    /* Special case: val = 0 */
    if (val == 0) {
        *UART_DATA = '0';
        return;
    }

    /* Convert number to decimal (reverse order) */
    while (val > 0) {
        buf[i++] = (val % 10) + '0';
        val = val / 10;
    }

    /* Send digits in correct order */
    while (i > 0) {
        *UART_DATA = buf[--i];
    }
}

char uart_getchar(void)
{
  unsigned char ch;

  /* UART gives 0xff when empty */
  while ((ch = *UART_DATA) == 0xff) {}

  return(ch);
}

void uart_putchar(char ch)
{
  *UART_DATA = ch;
}
  
void uart_puts(char *s)
{
  while (*s != 0) *UART_DATA = *s++;
}
