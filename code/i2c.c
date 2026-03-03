/* 
 * I2C Master Controller Implementation
 * Basic read/write functions for I2C communication
 */


#include "i2c.h"
#include "uart.h"

/* Initialize I2C controller */
void i2c_init(void)
{
    /* No special initialization needed */
    /* Hardware is ready after reset */
}

/* Write a single byte to I2C slave - NO WAIT VERSION */
void i2c_write_byte(unsigned char slave_addr, unsigned char data)
{
    unsigned int ctrl_val;

    /* Configure control register:
     * [15:8] = data to write
     * [7:1]   = 7-bit slave address
     * [0]     = 0 (write operation)
     */
    ctrl_val = ((unsigned int)data << 8) | ((unsigned int)(slave_addr & 0x7F) << 1) | I2C_WRITE;
    *I2C_CTRL = ctrl_val;
    // i2c_print_status();//testing

    /* Start the transaction */
    *I2C_START = 1;
    // i2c_print_status();//testing
    // i2c_wait_done();

    /* NO WAIT - return immediately for testing */
    /* The hardware will complete the transaction in the background */
}

/* Read a single byte from I2C slave - DISABLED FOR TESTING */
unsigned char i2c_read_byte(unsigned char slave_addr)
// {
//     /* Read operation disabled for testing */
//     /* Return dummy value */
//     return 0xFF;
// }
 /* Read a single byte from I2C slave */
// unsigned char i2c_read_byte(unsigned char slave_addr)
{
    unsigned int ctrl_val;
    unsigned int status;

    /* Configure control register:
     * [14:8]  = 7-bit slave address
     * [0]     = 1 (read operation)
     */
    ctrl_val = ((unsigned int)(slave_addr & 0x7F) << 8) | I2C_READ;
    *I2C_CTRL = ctrl_val;

    /* Start the transaction */
    *I2C_START = 1;

    /* Wait for completion */
    // i2c_wait_done();

    /* Read data from status register [3] */
    status = *I2C_STATUS;
    return (unsigned char)(status >> 3);
}

/* Get complete status register */
unsigned int i2c_get_status(void)
{
    return *I2C_STATUS;
}

unsigned int i2c_get_crtl(void)
{
    return *I2C_CTRL;
}
/* Check if I2C is busy */
unsigned char i2c_is_busy(void)
{
    return (*I2C_STATUS & I2C_BUSY) ? 1 : 0;
}

/* Check if transaction is done */
unsigned char i2c_is_done(void)
{
    return (*I2C_STATUS & I2C_DONE) ? 1 : 0;
}

/* Check if there was an ACK error */
unsigned char i2c_has_error(void)
{
    return (*I2C_STATUS & I2C_ACK_ERR) ? 1 : 0;
}

/* Wait for I2C transaction to complete */
void i2c_wait_done(void)
{
    unsigned int timeout = 0;
    while (!i2c_is_done() && timeout < 100000) {
        timeout++;
    }

    if (timeout >= 100000) {
        /* Timeout occurred */
        uart_puts("I2C timeout!\r\n");
    }
}

/* Print I2C status to UART */
void i2c_print_status(void)
{
    unsigned int status, control;
    unsigned char data;

    status = i2c_get_status();
    control = i2c_get_crtl();
    data = (unsigned char)(status >> 24);

    uart_puts("I2C Status reg: 0x");
    uart_print_hex(status);
    uart_puts("\r\n");
    uart_puts("I2C Ctrl Register: 0x");
    uart_print_hex(control);
    uart_puts("\r\n");
    // uart_puts("  st Register: 0x");
    // uart_puts("  Data: 0x");
    // uart_print_hex((unsigned int)i2c_get_status());
    // uart_puts("\r\n");

    // uart_puts("  Flags: ");
    // if (i2c_is_busy()) uart_puts("BUSY ");
    // if (i2c_is_done()) uart_puts("DONE ");
    // if (i2c_has_error()) uart_puts("ACK_ERR ");
    // uart_puts("\r\n");
}
