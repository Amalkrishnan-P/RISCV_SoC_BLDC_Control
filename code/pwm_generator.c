/*
Functions for PWM
*/

#include "pwm_generator.h"

#define PWM_CTRL ((volatile unsigned int *) 0x80000018)

void pwm_set_duty(const unsigned char duty)
{
    unsigned int val;
    
    // Clamp duty cycle to valid range (0-10)
    unsigned char clamped_duty = duty;
    if (clamped_duty > 10)
        clamped_duty = 10;
    
    // Read current value, preserve enable bit, update duty cycle
    val = *PWM_CTRL;
    val = (val & 0x10) | (clamped_duty & 0x0F);
    *PWM_CTRL = val;
}

void pwm_enable(void)
{
    unsigned int val;
    val = *PWM_CTRL;
    val |= 0x10;  // Set enable bit
    *PWM_CTRL = val;
}

void pwm_disable(void)
{
    unsigned int val;
    val = *PWM_CTRL;
    val &= ~0x10;  // Clear enable bit
    *PWM_CTRL = val;
}

void pwm_increase_duty(void)
{
    unsigned int val;
    unsigned char current_duty;
    
    val = *PWM_CTRL;
    current_duty = val & 0x0F;
    
    if (current_duty < 10) {
        current_duty++;
        val = (val & 0x10) | current_duty;
        *PWM_CTRL = val;
    }
}

void pwm_decrease_duty(void)
{
    unsigned int val;
    unsigned char current_duty;
    
    val = *PWM_CTRL;
    current_duty = val & 0x0F;
    
    if (current_duty > 0) {
        current_duty--;
        val = (val & 0x10) | current_duty;
        *PWM_CTRL = val;
    }
}

unsigned int pwm_read(void)
{
    return *PWM_CTRL;
}

unsigned char pwm_get_duty(void)
{
    return (*PWM_CTRL) & 0x0F;
}
