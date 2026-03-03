
void gpio_test(void)
{
  char gpio_cmd;
  unsigned char pin, val;
  
  uart_puts("\r\n--- GPIO Control ---\r\n");
  uart_puts("Commands: s=status, o=set output, i=set input,\r\n");
  uart_puts("          h=set high, l=set low, t=toggle, r=read,\r\n");
  uart_puts("          p=pattern test, a=all high, z=all low\r\n");
  uart_puts("GPIO> ");
  gpio_cmd = uart_getchar();
  uart_putchar(gpio_cmd);
  uart_puts("\r\n");
  
  switch(gpio_cmd) {
    case 's':
    case 'S':
      gpio_print_status();
      break;
      
    case 'o':
    case 'O':
      uart_puts("Pin (0-7): ");
      pin = uart_getchar() - '0';
      uart_putchar(pin + '0');
      uart_puts("\r\n");
      if (pin < 8) {
        gpio_set_pin_output(pin);
        uart_puts("Pin ");
        uart_putchar(pin + '0');
        uart_puts(" set as OUTPUT\r\n");
      } else {
        uart_puts("Invalid pin! Use 0-7\r\n");
      }
      break;
      
    case 'i':
    case 'I':
      uart_puts("Pin (0-7): ");
      pin = uart_getchar() - '0';
      uart_putchar(pin + '0');
      uart_puts("\r\n");
      if (pin < 8) {
        gpio_set_pin_input(pin);
        uart_puts("Pin ");
        uart_putchar(pin + '0');
        uart_puts(" set as INPUT\r\n");
      } else {
        uart_puts("Invalid pin! Use 0-7\r\n");
      }
      break;
      
    case 'h':
    case 'H':
      uart_puts("Pin (0-7): ");
      pin = uart_getchar() - '0';
      uart_putchar(pin + '0');
      uart_puts("\r\n");
      if (pin < 8) {
        gpio_set_pin(pin);
        uart_puts("Pin ");
        uart_putchar(pin + '0');
        uart_puts(" set HIGH\r\n");
      } else {
        uart_puts("Invalid pin! Use 0-7\r\n");
      }
      break;
      
    case 'l':
    case 'L':
      uart_puts("Pin (0-7): ");
      pin = uart_getchar() - '0';
      uart_putchar(pin + '0');
      uart_puts("\r\n");
      if (pin < 8) {
        gpio_clear_pin(pin);
        uart_puts("Pin ");
        uart_putchar(pin + '0');
        uart_puts(" set LOW\r\n");
      } else {
        uart_puts("Invalid pin! Use 0-7\r\n");
      }
      break;
      
    case 't':
    case 'T':
      uart_puts("Pin (0-7): ");
      pin = uart_getchar() - '0';
      uart_putchar(pin + '0');
      uart_puts("\r\n");
      if (pin < 8) {
        gpio_toggle_pin(pin);
        uart_puts("Pin ");
        uart_putchar(pin + '0');
        uart_puts(" toggled\r\n");
      } else {
        uart_puts("Invalid pin! Use 0-7\r\n");
      }
      break;
      
    case 'r':
    case 'R':
      uart_puts("Reading all pins:\r\n");
      gpio_print_status();
      break;
      
    case 'p':
    case 'P':
      uart_puts("Running pattern test...\r\n");
      gpio_test_pattern();
      break;
      
    case 'a':
    case 'A':
      uart_puts("Setting all pins as OUTPUT and HIGH\r\n");
      gpio_set_direction(0xFF, GPIO_OUTPUT);
      gpio_write_port(0xFF);
      gpio_print_status();
      break;
      
    case 'z':
    case 'Z':
      uart_puts("Setting all pins as OUTPUT and LOW\r\n");
      gpio_set_direction(0xFF, GPIO_OUTPUT);
      gpio_write_port(0x00);
      gpio_print_status();
      break;
      
    default:
      uart_puts("Unknown GPIO command\r\n");
      uart_puts("\r\nAvailable commands:\r\n");
      uart_puts("  s - Show status\r\n");
      uart_puts("  o - Set pin as output\r\n");
      uart_puts("  i - Set pin as input\r\n");
      uart_puts("  h - Set pin high\r\n");
      uart_puts("  l - Set pin low\r\n");
      uart_puts("  t - Toggle pin\r\n");
      uart_puts("  r - Read all pins\r\n");
      uart_puts("  p - Run pattern test\r\n");
      uart_puts("  a - All pins high\r\n");
      uart_puts("  z - All pins low\r\n");
      break;
  }
}