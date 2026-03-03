void pwm_test(void)
{
  unsigned int val;
  unsigned char duty;

  uart_puts("\r\nPWM Generator Test\r\n");

  // Test basic write and read
  pwm_set_duty(5);
  pwm_enable();
  val = pwm_read();
  duty = pwm_get_duty();

  uart_puts("PWM Control Register: ");
  uart_print_hex(val);
  uart_puts("\r\nDuty Cycle: ");
  uart_print_hex((unsigned int)duty);
  uart_puts(" (should be 5 = 50%)\r\n");

  if (duty == 5 && (val & 0x10)) {
    uart_puts("PWM test PASSED\r\n");
  } else {
    uart_puts("PWM test FAILED\r\n");
  }
}
//Live testing
void pwm_interactive_test(void)
{
    unsigned char ch, duty;

    uart_puts("\r\n=== Interactive I2C Test ===\r\n");
    uart_puts("Commands (type during operation):\r\n");
    uart_puts("  '+' = Increase PWM duty cycle by 10%\r\n");
    uart_puts("  '-' = Decrease PWM duty cycle by 10%\r\n");
    uart_puts("  'D' = Disable PWM\r\n");
    uart_puts("  'E' = Enable PWM\r\n");
    uart_puts("  'S' = Show system status\r\n");
    uart_puts("\r\nPress any key to start...\r\n");
    (void) uart_getchar();

    // /* Check for UART commands (non-blocking if available) */
    // uart_puts("Enter command (+, -, b, s) or wait...\r\n");

    // /* Small delay to allow command input */
    // cdt_delay(27000000);  // 1 second delay

    /* Check if there's a command waiting */
    ch = uart_getchar();  // This will wait if no character available
    uart_putchar(ch);  // Echo
    uart_puts("\r\n");

    switch(ch) {
        case '+':
          pwm_increase_duty();
          duty = pwm_get_duty();
          uart_puts("PWM duty increased to ");
          uart_print_dec((unsigned int)duty);
          uart_puts(" (");
          uart_print_dec((unsigned int)duty * 10);
          uart_puts("%)\r\n");
          break;

        case '-':
          pwm_decrease_duty();
          duty = pwm_get_duty();
          uart_puts("PWM duty decreased to ");
          uart_print_dec((unsigned int)duty);
          uart_puts(" (");
          uart_print_dec((unsigned int)duty * 10);
          uart_puts("%)\r\n");
          break;

        case 'd':
        case 'D':
          pwm_disable();
          break;

        case 'e':
        case 'E':
          pwm_enable();
          break;

        default:
          uart_puts("Unknown command. Use +, -, d, e, or s\r\n");
          break;
    }
}