#ifndef _BLDC_H
#define _BLDC_H

/* BLDC Commutator register addresses */
#define BLDC_STATUS       ((volatile unsigned int *) 0x8000001C)
#define BLDC_HALL_CTRL    ((volatile unsigned int *) 0x80000020)

/* Hall control register bits */
#define BLDC_USE_GPIO_HALL  (1 << 3)  // Use GPIO-controlled Hall sensors
#define BLDC_HALL_HA        (1 << 2)  // Hall sensor A value
#define BLDC_HALL_HB        (1 << 1)  // Hall sensor B value
#define BLDC_HALL_HC        (1 << 0)  // Hall sensor C value

/* Function prototypes */
extern void bldc_init(void);
extern unsigned int bldc_read_status(void);
extern unsigned int bldc_get_sector(void);
extern unsigned int bldc_get_hall_sensors(void);
extern unsigned int bldc_get_gate_signals(void);

/* GPIO Hall sensor control (for testing) */
extern void bldc_set_hall_sensors(unsigned char ha, unsigned char hb, unsigned char hc);
extern void bldc_use_gpio_hall(unsigned char enable);
extern void bldc_use_hardware_hall(void);

/* Status display */
extern void bldc_print_status(void);

#endif /* _BLDC_H */
