#include <stdint.h>

#include "../../bsp/include/gpio.h"
#include "../../bsp/include/utils.h"

void gpio_set_mode(gpio_e gpio, gpio_mode_e mode)
{
    GPIO_REG(GPIO_IO_MODE_REG_OFFSET) &= ~(0x3 << (gpio << 1));
    GPIO_REG(GPIO_IO_MODE_REG_OFFSET) |= ((uint8_t)mode) << (gpio << 1);
}

uint8_t gpio_get_input_data(gpio_e gpio)
{
    if (GPIO_REG(GPIO_DATA_REG_OFFSET) & (1 << gpio))
        return 1;
    else
        return 0;
}

void gpio_set_output_data(gpio_e gpio, uint8_t data)
{
    if (data)
        GPIO_REG(GPIO_DATA_REG_OFFSET) |= 1 << gpio;
    else
        GPIO_REG(GPIO_DATA_REG_OFFSET) &= ~(1 << gpio);
}

void gpio_set_output_toggle(gpio_e gpio)
{
    GPIO_REG(GPIO_DATA_REG_OFFSET) ^= 1 << gpio;
}

void gpio_set_input_filter_enable(gpio_e gpio, uint8_t en)
{
    if (en)
        GPIO_REG(GPIO_FILTER_REG_OFFSET) |= 1 << gpio;
    else
        GPIO_REG(GPIO_FILTER_REG_OFFSET) &= ~(1 << gpio);
}

void gpio_set_interrupt_mode(gpio_e gpio, gpio_intr_mode_e mode)
{
    GPIO_REG(GPIO_INT_MODE_REG_OFFSET) &= ~(0x3 << (gpio << 1));
    GPIO_REG(GPIO_INT_MODE_REG_OFFSET) |= ((uint8_t)mode) << (gpio << 1);
}

void gpio_clear_intr_pending(gpio_e gpio)
{
    GPIO_REG(GPIO_INT_PENDING_REG_OFFSET) |= 1 << gpio;
}

uint8_t gpio_get_intr_pending(gpio_e gpio)
{
    if (GPIO_REG(GPIO_INT_PENDING_REG_OFFSET) & (1 << gpio))
        return 1;
    else
        return 0;
}
