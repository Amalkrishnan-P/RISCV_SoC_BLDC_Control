/* 
   SoC Program
*/

#include "leds.h"
#include "uart.h"
#include "countdown_timer.h"
#include "pwm_generator.h"
#include "bldc.h"
#include "i2c.h"
#include "gpio.h"

#define ENABLE_BLDC
#define ENABLE_GPIO
#define ENABLE_PWM
#define ENABLE_I2C

#ifdef ENABLE_BLDC
void bldc_interactive_test(void)
{
    char ch;
    unsigned char ha, hb, hc;

    uart_puts("\r\n=== BLDC Interactive Hall Sensor Test ===\r\n");
    uart_puts("Commands:\r\n");
    uart_puts("  1-6: Set Hall sensors for Sector 1-6\r\n");
    uart_puts("  h: Switch to Hardware Hall sensors\r\n");
    uart_puts("  s: Show current status\r\n");
    uart_puts("  q: Quit test\r\n\r\n");

    while (1) {
        uart_puts("Enter command: ");
        ch = uart_getchar();
        uart_putchar(ch);
        uart_puts("\r\n");

        switch(ch) {
            case '1':  // Sector 1: 001
                uart_puts("Sector 1: Hall=001, Gates should be g1,g4\r\n");
                bldc_set_hall_sensors(0, 0, 1);
                bldc_print_status();
                break;

            case '2':  // Sector 2: 010
                uart_puts("Sector 2: Hall=010, Gates should be g3,g6\r\n");
                bldc_set_hall_sensors(0, 1, 0);
                bldc_print_status();
                break;

            case '3':  // Sector 3: 011
                uart_puts("Sector 3: Hall=011, Gates should be g2,g3\r\n");
                bldc_set_hall_sensors(0, 1, 1);
                bldc_print_status();
                break;

            case '4':  // Sector 4: 100
                uart_puts("Sector 4: Hall=100, Gates should be g2,g5\r\n");
                bldc_set_hall_sensors(1, 0, 0);
                bldc_print_status();
                break;

            case '5':  // Sector 5: 101
                uart_puts("Sector 5: Hall=101, Gates should be g1,g6\r\n");
                bldc_set_hall_sensors(1, 0, 1);
                bldc_print_status();
                break;

            case '6':  // Sector 6: 110
                uart_puts("Sector 6: Hall=110, Gates should be g4,g5\r\n");
                bldc_set_hall_sensors(1, 1, 0);
                bldc_print_status();
                break;

            case 'h':
            case 'H':
                uart_puts("Switching to Hardware Hall sensors\r\n");
                bldc_use_hardware_hall();
                bldc_print_status();
                break;

            case 's':
            case 'S':
                bldc_print_status();
                break;

            case 'q':
            case 'Q':
                uart_puts("Exiting BLDC test\r\n");
                return;

            default:
                uart_puts("Unknown command\r\n");
                break;
        }
        uart_puts("\r\n");
    }
}
#endif

#ifdef ENABLE_GPIO
void gpio_test(void)
{
while(1)
{
  char gpio_cmd;
  unsigned char pin, val;
  
  uart_puts("\r\n===   GPIO Control  ===\r\n");
  uart_puts("Commands:\r\n");
  uart_puts("  s: Show status\r\n");
  uart_puts("  i: Set pin as input\r\n");
  // uart_puts("  h: Set high\r\n");
  // uart_puts("  l: Set low\r\n");
  uart_puts("  a: Set all high\r\n");
  uart_puts("  z: Set all low\r\n");
  uart_puts("  q: Quit\r\n\r\n");
  uart_puts("GPIO> ");
  gpio_cmd = uart_getchar();
  uart_putchar(gpio_cmd);
  uart_puts("\r\n");
  
  switch(gpio_cmd) {
    case 's':
    case 'S':
      gpio_print_status();
      break;
      
    // case 'o':
    // case 'O':
    //   uart_puts("Pin (0-7): ");
    //   pin = uart_getchar();
    //   uart_putchar(pin + '0');
    //   uart_puts("\r\n");
    //   if (pin < 8) {
    //     gpio_set_pin_output(pin);
    //     uart_puts("Pin ");
    //     uart_putchar(pin + '0');
    //     uart_puts(" set as OUTPUT\r\n");
    //   } else {
    //     uart_puts("Invalid pin! Use 0-7\r\n");
    //   }
    //   break;
      
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
      
    // case 'h':
    // case 'H':
    //   uart_puts("Pin (0-7): ");
    //   pin = uart_getchar() - '0';
    //   uart_putchar(pin + '0');
    //   uart_puts("\r\n");
    //   if (pin < 8) {
    //     gpio_set_pin(pin);
    //     uart_puts("Pin ");
    //     uart_putchar(pin + '0');
    //     uart_puts(" set HIGH\r\n");
    //   } else {
    //     uart_puts("Invalid pin! Use 0-7\r\n");
    //   }
    //   break;
      
    // case 'l':
    // case 'L':
    //   uart_puts("Pin (0-7): ");
    //   pin = uart_getchar() - '0';
    //   uart_putchar(pin + '0');
    //   uart_puts("\r\n");
    //   if (pin < 8) {
    //     gpio_clear_pin(pin);
    //     uart_puts("Pin ");
    //     uart_putchar(pin + '0');
    //     uart_puts(" set LOW\r\n");
    //   } else {
    //     uart_puts("Invalid pin! Use 0-7\r\n");
    //   }
    //   break;
      
    // case 't':
    // case 'T':
    //   uart_puts("Pin (0-7): ");
    //   pin = uart_getchar() - '0';
    //   uart_putchar(pin + '0');
    //   uart_puts("\r\n");
    //   if (pin < 8) {
    //     gpio_toggle_pin(pin);
    //     uart_puts("Pin ");
    //     uart_putchar(pin + '0');
    //     uart_puts(" toggled\r\n");
    //   } else {
    //     uart_puts("Invalid pin! Use 0-7\r\n");
    //   }
    //   break;
      
    // case 'r':
    // case 'R':
    //   uart_puts("Reading all pins:\r\n");
    //   gpio_print_status();
    //   break;
      
    // case 'p':
    // case 'P':
    //   uart_puts("Running pattern test...\r\n");
    //   gpio_test_pattern();
    //   break;
      
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
    case 'q':
    case 'Q':
     return; 
      
    default:
      uart_puts("Unknown GPIO command\r\n");
      break;
    }
  }
}
#endif

#ifdef ENABLE_PWM
void pwm_interactive_test(void)
{
  while (1)
  {
    unsigned char ch, duty;

    uart_puts("\r\n=== Interactive PWM Test ===\r\n");
    uart_puts("Commands (type during operation):\r\n");
    uart_puts("  '+' = Increase PWM duty cycle by 10%\r\n");
    uart_puts("  '-' = Decrease PWM duty cycle by 10%\r\n");
    uart_puts("  'D' = Disable PWM\r\n");
    uart_puts("  'E' = Enable PWM\r\n");
    uart_puts("  'S' = Show system status\r\n");
    // uart_puts("\r\nPress any key to start...\r\n");
    // (void) uart_getchar();

    /* Check for UART commands (non-blocking if available) */
    uart_puts("Enter command (+, -, b, s) or wait...\r\n");

    /* Small delay to allow command input */
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
        case 'q':
        case 'Q':
         return;          
        default:
          uart_puts("Unknown command. Use +, -, d, e, or s\r\n");
          break;
    }
  }
}
#endif

#ifdef ENABLE_I2C
void i2c_interactive_test(void)
{
    char ch;
    unsigned char addr, data;

    uart_puts("\r\n=== Interactive I2C Test ===\r\n");
    uart_puts("Commands:\r\n");
    uart_puts("  '1' = READ from 0x1A \r\n");
    uart_puts("  '2' = Write 0x55 to 0x10\r\n");
    uart_puts("  '3' = Write 0xFF to 0x1C\r\n");
    uart_puts("  's' = Show status\r\n");
    uart_puts("  'q' = Quit\r\n\r\n");

    while (1) {
        uart_puts("I2C> ");
        ch = uart_getchar();
        uart_putchar(ch);
        uart_puts("\r\n");

        switch(ch) {
            case '1':
                uart_puts("Reading form 0x1A...\r\n");
                i2c_read_byte(0x1A);
                i2c_wait_done();
                i2c_print_status();
                break;

            case '2':
                uart_puts("Writing 0x55 to 0x10...\r\n");
                i2c_write_byte(0x10, 0x55);
                uart_print_hex((unsigned int)i2c_get_status);
                uart_puts("...\r\n");
                cdt_delay(5700000);
                uart_print_hex((unsigned int)i2c_get_status);
                uart_puts("...\r\n");
                i2c_print_status();
                break;

            case '3':
                uart_puts("Writing 0xFF to 0x1C...\r\n");
                i2c_write_byte(0x1C, 0xFF);
                cdt_delay(5700000);
                i2c_print_status();
                break;

            case 's':
            case 'S':
                i2c_print_status();
                break;

            case 'q':
            case 'Q':
                uart_puts("Exiting I2C test\r\n");
                return;

            default:
                uart_puts("Unknown command\r\n");
                break;
        }
        uart_puts("\r\n");
    }
}
#endif

int main()
{
  int led_val;
  int i;

  set_leds(0);// testing purpose

  uart_set_div(234); /* 27000000/115200 */

  /* Test Timer*/
  // cdt_test();

  /* Test PWM */
  // pwm_test();

  /* Test UART input */
  // uart_rx_test();


  /* Main control loop */
  i = 0;
  while (1) {

    uart_puts("\r\n           Loop ");
    uart_print_dec(i);
    uart_puts("\r\n");
    
    led_val = get_leds();
    set_leds(led_val+1);

    /* Test GPIO Pins */
    #ifdef ENABLE_GPIO
    gpio_test();
    #endif

    /* Test BLDC Commutator */
    #ifdef ENABLE_BLDC
    bldc_interactive_test();
    #endif

    /* Test I2C module */
    #ifdef ENABLE_I2C
    i2c_interactive_test();
    #endif

    /* Test PWM module */
    #ifdef ENABLE_PWM
    pwm_interactive_test();
    #endif

    i += 1;
  }
  return 0;
}
