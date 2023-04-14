#ifndef _FLASH_GD25Q_H_
#define _FLASH_GD25Q_H_

#define GD25Q_PAGE_SIZE 	                (256)

#define GD25Q_PAGE_TO_ADDR(page)            ((page) << 8)
#define GD25Q_SECTOR_TO_ADDR(sector)        ((sector) << 12)

#define CMD_WRITE_STATUS_REG1		        (0x01)
#define CMD_WRITE_STATUS_REG2		        (0x31)
#define CMD_WRITE_STATUS_REG3		        (0x11)
#define CMD_READ_STATUS_REG1 		        (0x05)
#define CMD_READ_STATUS_REG2 		        (0x35)
#define CMD_READ_STATUS_REG3 		        (0x15)
#define CMD_PAGE_PROGRAM			        (0x02)
#define CMD_QUAD_PAGE_PROGRAM			    (0x32)
#define CMD_READ 					        (0x03)
#define CMD_QUAD_IO_FAST_READ               (0xeb)
#define CMD_WRITE_ENABLE 			        (0x06)
#define CMD_WRITE_DISABLE 			        (0x04)
#define CMD_SECTOR_ERASE			        (0x20)
#define CMD_BLOCK32K_ERASE                  (0x52)
#define CMD_BLOCK64K_ERASE                  (0xd8)
#define CMD_READ_ID                         (0x90)
#define CMD_QUAD_IO_READ_ID                 (0x94)

#define DUMMY_CNT                           (0x4)

typedef struct {
    uint8_t manf_id;
    uint8_t dev_id;
} gd25q_id_t;

void flash_gd25q_init(uint32_t controller, uint16_t clk_div);
void flash_gd25q_set_spi_mode(uint8_t mode);
void flash_gd25q_set_spi_controller(uint32_t controller);
gd25q_id_t flash_gd25q_read_id();
void flash_gd25q_write_enable(uint8_t en);
uint8_t flash_gd25q_read_reg(uint8_t cmd);
void flash_gd25q_write_reg(uint8_t cmd, uint8_t data);
uint8_t flash_gd25q_is_busy();
void flash_gd25q_read(uint8_t data[], uint32_t len, uint32_t addr);
void flash_gd25q_sector_erase(uint32_t sector);
void flash_gd25q_page_program(uint8_t data[], uint32_t len, uint32_t page);
void flash_gd25q_enable_quad_mode(uint8_t en);

#endif
