/* 
   Driver functions for 8-Pin GPIO IP
*/

#include "gpio.h"
#include "uart.h"

/* Set direction for multiple pins using a mask */
void gpio_set_direction(unsigned char pin_mask, unsigned char direction)
{
    unsigned int current_dir = *GPIO_DIR;
    
    if (direction == GPIO_OUTPUT) {
        // Set pins as output
        *GPIO_DIR = current_dir | (pin_mask & 0xFF);
    } else {
        // Set pins as input
        *GPIO_DIR = current_dir & ~(pin_mask & 0xFF);
    
}
}
/* Set a single pin as output */
void gpio_set_pin_output(unsigned char pin)
{
    if (pin < 8) {
        *GPIO_DIR |= (1 << pin);
    }
}

/* Set a single pin as input */
void gpio_set_pin_input(unsigned char pin)
{
    if (pin < 8) {
        *GPIO_DIR &= ~(1 << pin);
    }
}

/* Get current direction register */
unsigned int gpio_get_direction(void)
{
    return (*GPIO_DIR & 0xFF);
}

/* Write a value to a pin (0 or 1) */
void gpio_write_pin(unsigned char pin, unsigned char value)
{
    if (pin < 8) {
        if (value) {
            gpio_set_pin(pin);
        } else {
            gpio_clear_pin(pin);
        }
    }
}

/* Set a pin high */
void gpio_set_pin(unsigned char pin)
{
    if (pin < 8) {
        *GPIO_SET = (1 << pin);
    }
}

/* Clear a pin low */
void gpio_clear_pin(unsigned char pin)
{
    if (pin < 8) {
        *GPIO_CLR = (1 << pin);
    }
}

/* Toggle a pin */
void gpio_toggle_pin(unsigned char pin)
{
    if (pin < 8) {
        unsigned int current = *GPIO_OUT;
        if (current & (1 << pin)) {
            gpio_clear_pin(pin);
        } else {
            gpio_set_pin(pin);
        }
    }
}

/* Write all 8 pins at once */
void gpio_write_port(unsigned char value)
{
    // First clear all pins
    *GPIO_CLR = 0xFF;
    // Then set the desired bits
    *GPIO_SET = (value & 0xFF);
}

/* Read a single pin */
unsigned int gpio_read_pin(unsigned char pin)
{
    if (pin < 8) {
        unsigned int in_val = *GPIO_IN;
        return (in_val >> pin) & 0x01;
    }
    return 0;
}

/* Read all pins */
unsigned int gpio_read_port(void)
{
    return (*GPIO_IN & 0xFF);
}

/* Print GPIO status */
void gpio_print_status(void)
{
    unsigned int dir, in_val, out_val;
    int i;
    
    dir = gpio_get_direction();
    in_val = gpio_read_port();
    out_val = *GPIO_OUT & 0xFF;
    
    uart_puts("\r\nGPIO Status:\r\n");
    uart_puts("  Pin | Dir    | Out | In\r\n");
    uart_puts("  ----|--------|-----|----\r\n");
    
    for (i = 0; i < 8; i++) {
        uart_puts("   ");
        uart_putchar('0' + i);
        uart_puts("  | ");
        
        // Direction
        if (dir & (1 << i)) {
            uart_puts("OUTPUT");
        } else {
            uart_puts("INPUT ");
        }
        uart_puts(" |  ");
        
        // Output value
        uart_putchar((out_val & (1 << i)) ? '1' : '0');
        uart_puts("  | ");
        
        // Input value
        uart_putchar((in_val & (1 << i)) ? '1' : '0');
        uart_puts("\r\n");
    }
    
    uart_puts("\r\n");
    uart_puts("  DIR register:  0x");
    uart_print_hex(dir);
    uart_puts("\r\n");
    uart_puts("  OUT register:  0x");
    uart_print_hex(out_val);
    uart_puts("\r\n");
    uart_puts("  IN register:   0x");
    uart_print_hex(in_val);
    uart_puts("\r\n");
}

/* Test pattern - blink all pins in sequence */
void gpio_test_pattern(void)
{
    int i, j;
    
    uart_puts("\r\n=== GPIO Test Pattern ===\r\n");
    uart_puts("Setting all pins as outputs...\r\n");
    
    // Set all pins as outputs
    *GPIO_DIR = 0xFF;
    
    // Clear all pins
    *GPIO_CLR = 0xFF;
    
    uart_puts("Running test pattern (4 cycles)...\r\n");
    
    for (j = 0; j < 4; j++) {
        for (i = 0; i < 8; i++) {
            // Set current pin high
            gpio_set_pin(i);
            
            uart_puts("  Pin ");
            uart_putchar('0' + i);
            uart_puts(" HIGH\r\n");
            
            // Small delay (you can adjust this)
            for (volatile int delay = 0; delay < 100000; delay++) {}
            
            // Clear current pin
            gpio_clear_pin(i);
        }
    }
    
    uart_puts("Test pattern complete\r\n");
    uart_puts("\r\n");
}

/* Utility: Print binary representation of an 8-bit value */
void gpio_print_binary(unsigned char value)
{
    int i;
    for (i = 7; i >= 0; i--) {
        uart_putchar((value & (1 << i)) ? '1' : '0');
    }
}