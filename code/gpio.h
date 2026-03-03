/* 
   Header file for 8-Pin GPIO controller
*/

#ifndef _GPIO_8PIN_H
#define _GPIO_8PIN_H

/* Base address for 8-Pin GPIO */
#define GPIO_BASE 0x80000040

/* Register offsets */
#define GPIO_DIR  ((volatile unsigned int *)(GPIO_BASE + 0x00))  // Direction
#define GPIO_SET  ((volatile unsigned int *)(GPIO_BASE + 0x04))  // Set output high
#define GPIO_CLR  ((volatile unsigned int *)(GPIO_BASE + 0x08))  // Clear output low
#define GPIO_IN   ((volatile unsigned int *)(GPIO_BASE + 0x0C))  // Input values
#define GPIO_OUT  ((volatile unsigned int *)(GPIO_BASE + 0x10))  // Output register

/* Pin bit positions */
#define GPIO_PIN0 (1 << 0)
#define GPIO_PIN1 (1 << 1)
#define GPIO_PIN2 (1 << 2)
#define GPIO_PIN3 (1 << 3)
#define GPIO_PIN4 (1 << 4)
#define GPIO_PIN5 (1 << 5)
#define GPIO_PIN6 (1 << 6)
#define GPIO_PIN7 (1 << 7)

/* Direction values */
#define GPIO_INPUT  0
#define GPIO_OUTPUT 1

/* Function prototypes */

/* Pin direction control */
extern void gpio_set_direction(unsigned char pin_mask, unsigned char direction);
extern void gpio_set_pin_output(unsigned char pin);
extern void gpio_set_pin_input(unsigned char pin);
extern unsigned int gpio_get_direction(void);

/* Output control */
extern void gpio_write_pin(unsigned char pin, unsigned char value);
extern void gpio_set_pin(unsigned char pin);
extern void gpio_clear_pin(unsigned char pin);
extern void gpio_toggle_pin(unsigned char pin);
extern void gpio_write_port(unsigned char value);

/* Input reading */
extern unsigned int gpio_read_pin(unsigned char pin);
extern unsigned int gpio_read_port(void);

/* Utility functions */
extern void gpio_print_status(void);
extern void gpio_test_pattern(void);

#endif /* _GPIO_8PIN_H */