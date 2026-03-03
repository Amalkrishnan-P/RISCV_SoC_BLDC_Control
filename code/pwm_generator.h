#ifndef PWM_GENERATOR_H
#define PWM_GENERATOR_H

/* 
 * 
 * PWM Generator Control Functions
 * 
 * The PWM generator creates a variable duty cycle PWM signal.
 * Duty cycle can be set from 0 (0%) to 10 (100%) in 10% increments.
 */

/* Set the duty cycle (0-10, where 10 = 100%) and enable PWM */
extern void pwm_set_duty(const unsigned char duty);

/* Enable PWM output with current duty cycle */
extern void pwm_enable(void);

/* Disable PWM output */
extern void pwm_disable(void);

/* Increase duty cycle by 10% (up to 100%) */
extern void pwm_increase_duty(void);

/* Decrease duty cycle by 10% (down to 0%) */
extern void pwm_decrease_duty(void);

/* Read current PWM configuration (returns duty cycle in bits [3:0], enable in bit [4]) */
extern unsigned int pwm_read(void);

/* Get current duty cycle value (0-10) */
extern unsigned char pwm_get_duty(void);

#endif
