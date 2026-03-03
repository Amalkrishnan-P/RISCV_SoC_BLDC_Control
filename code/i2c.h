/* I2C Master Controller Interface
 * Header file for basic I2C read/write operations
 */

#ifndef _I2C_H
#define _I2C_H

/* I2C register addresses */
#define I2C_CTRL     ((volatile unsigned int *) 0x80000024)
#define I2C_STATUS   ((volatile unsigned int *) 0x80000028)
#define I2C_START    ((volatile unsigned int *) 0x8000002C)

/* Status register bit positions */
#define I2C_ACK_ERR  (1 << 0)
#define I2C_BUSY     (1 << 1)
#define I2C_DONE     (1 << 2)

/* Operation types */
#define I2C_WRITE    0
#define I2C_READ     1

/* Function prototypes */
extern void i2c_init(void);
extern void i2c_write_byte(unsigned char slave_addr, unsigned char data);
extern unsigned char i2c_read_byte(unsigned char slave_addr);
extern unsigned int i2c_get_status(void);
extern unsigned int i2c_get_ctrl(void);
extern unsigned char i2c_is_busy(void);
extern unsigned char i2c_is_done(void);
extern unsigned char i2c_has_error(void);
extern void i2c_wait_done(void);
extern void i2c_print_status(void);

#endif /* _I2C_H */
