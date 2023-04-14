#include <stdint.h>

#include "../../bsp/include/flash_ctrl.h"
#include "../../bsp/include/utils.h"

void flash_ctrl_sector_erase(uint32_t sector_addr_offset)
{
    FLASH_CTRL(sector_addr_offset | FLASH_CTRL_SECTOR_ERASE_FLAG) = 0x0;
}

void flash_ctrl_write(uint32_t offset, uint32_t data)
{
    FLASH_CTRL(offset) = data;
}

void flash_ctrl_read(uint32_t offset, uint32_t *data)
{
    *data = FLASH_CTRL(offset);
}
