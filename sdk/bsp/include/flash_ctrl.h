#ifndef _FLASH_CTRL_H_
#define _FLASH_CTRL_H_

#ifdef __cplusplus
extern "C" {
#endif

#define FLASH_CTRL_SECTOR_ERASE_FLAG (1 << 23)
#define FLASH_CTRL(offset) (*((volatile uint32_t *)(0x02000000 + (offset))))

void flash_ctrl_sector_erase(uint32_t sector_addr_offset);
void flash_ctrl_write(uint32_t offset, uint32_t data);
void flash_ctrl_read(uint32_t offset, uint32_t *data);

#ifdef __cplusplus
}  // extern "C"
#endif
#endif
