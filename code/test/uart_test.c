// void uart_rx_test(void)
// {
//   char buf[5];
//   int i;

//   uart_puts("Type 3 characters (they will printed again): ");
//   for (i = 0; i < 3; i++) {
//     buf[i] = uart_getchar();
//     uart_putchar(buf[i]);
//   }
//   buf[3] = 0;
//   uart_puts("\r\nUART read: ");
//   uart_puts(buf);
//   uart_puts("\r\n");
// }