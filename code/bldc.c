/* BLDC Commutator Interface
 * Implementation file for six-step BLDC commutation control
 */


#include "bldc.h"
#include "uart.h"

/* Initialize BLDC commutator */
void bldc_init(void)
{
    /* Start with GPIO Hall sensors disabled (use hardware pins) */
    bldc_use_hardware_hall();
}

/* Read the complete status register */
unsigned int bldc_read_status(void)
{
    return *BLDC_STATUS;
}

/* Get current sector (0-6, where 0 = invalid hall combination) */
unsigned int bldc_get_sector(void)
{
    unsigned int status = bldc_read_status();
    return (status >> 9) & 0x07;  // Extract bits [11:9]
}

/* Get hall sensor values */
unsigned int bldc_get_hall_sensors(void)
{
    unsigned int status = bldc_read_status();
    return (status >> 6) & 0x07;  // Extract bits [8:6] = {ha, hb, hc}
}

/* Get gate signals */
unsigned int bldc_get_gate_signals(void)
{
    unsigned int status = bldc_read_status();
    return status & 0x3F;  // Extract bits [5:0] = {g6, g5, g4, g3, g2, g1}
}

/* Set Hall sensor values via GPIO (for testing)
 * ha, hb, hc: 0 or 1
 * This function automatically enables GPIO mode
 */
void bldc_set_hall_sensors(unsigned char ha, unsigned char hb, unsigned char hc)
{
    unsigned int val = 0;

    // Build control value
    val |= BLDC_USE_GPIO_HALL;  // Enable GPIO mode
    if (ha) val |= BLDC_HALL_HA;
    if (hb) val |= BLDC_HALL_HB;
    if (hc) val |= BLDC_HALL_HC;

    // Write to Hall control register
    *BLDC_HALL_CTRL = val;
}

/* Enable GPIO-controlled Hall sensors */
void bldc_use_gpio_hall(unsigned char enable)
{
    unsigned int val = *BLDC_HALL_CTRL;

    if (enable) {
        val |= BLDC_USE_GPIO_HALL;
    } else {
        val &= ~BLDC_USE_GPIO_HALL;
    }

    *BLDC_HALL_CTRL = val;
}

/* Switch to hardware Hall sensor pins */
void bldc_use_hardware_hall(void)
{
    *BLDC_HALL_CTRL = 0;  // Clear all bits, use hardware
}

/* Print BLDC status to UART */
void bldc_print_status(void)
{
    unsigned int sector, hall, gates, hall_ctrl;
    int i;

    sector = bldc_get_sector();
    hall = bldc_get_hall_sensors();
    gates = bldc_get_gate_signals();
    hall_ctrl = *BLDC_HALL_CTRL;

    uart_puts("BLDC Status:\r\n");

    uart_puts("  Hall Source: ");
    if (hall_ctrl & BLDC_USE_GPIO_HALL) {
        uart_puts("GPIO (Software)\r\n");
    } else {
        uart_puts("Hardware Pins\r\n");
    }

    uart_puts("  Sector: ");
    uart_print_hex(sector);
    uart_puts("\r\n");

    uart_puts("  Hall Sensors (ha,hb,hc): ");
    uart_putchar('0' + ((hall >> 2) & 1));  // ha
    uart_putchar('0' + ((hall >> 1) & 1));  // hb
    uart_putchar('0' + (hall & 1));         // hc
    uart_puts("\r\n");

    uart_puts("  Gate Signals: 0x");
    uart_print_hex(gates);
    uart_puts(" (g6-g1): ");
    for (i = 5; i >= 0; i--) {
        uart_putchar('0' + ((gates >> i) & 1));
    }
    uart_puts("\r\n");

    /* Show which gates are active */
    uart_puts("  Active Gates: ");
    for (i = 0; i < 6; i++) {
        if ((gates >> i) & 1) {
            uart_putchar('g');
            uart_putchar('1' + i);
            uart_putchar(' ');
        }
    }
    uart_puts("\r\n");
}
