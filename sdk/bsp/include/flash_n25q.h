#ifndef _FLASH_N25Q_H_
#define _FLASH_N25Q_H_


#define N25Q_PAGE_SIZE 	                    (256)

#define N25Q_PAGE_TO_ADDR(page)             (page << 8)
#define N25Q_SUBSECTOR_TO_ADDR(subsector)   (subsector << 12)
#define N25Q_SECTOR_TO_ADDR(sector)         (sector << 16)

#define CMD_WRITE_STATUS_REG		        (0x01)
#define CMD_PAGE_PROGRAM			        (0x02)
#define CMD_READ 					        (0x03)
#define CMD_FAST_READ                       (0x0b)
#define CMD_QUAD_OUTPUT_FAST_READ           (0x6b)
#define CMD_WRITE_DISABLE 			        (0x04)
#define CMD_READ_STATUS_REG 		        (0x05)
#define CMD_WRITE_ENABLE 			        (0x06)
#define CMD_SUBSECTOR_ERASE			        (0x20)
#define CMD_CLEAR_FLAG_STATUS_REG	        (0x50)
#define CMD_READ_FLAG_STATUS_REG	        (0x70)
#define CMD_BULK_ERASE				        (0xC7)
#define CMD_SECTOR_ERASE			        (0xD8)
#define CMD_WRITE_LOCK_REG  		        (0xE5)
#define CMD_READ_LOCK_REG   		        (0xE8)
#define CMD_READ_ID                         (0x9F)
#define CMD_MULTI_IO_READ_ID                (0xAF)
#define CMD_WRITE_ENHANCED_VOL_CONF_REG     (0x61)
#define CMD_READ_ENHANCED_VOL_CONF_REG      (0x65)
#define CMD_READ_VOL_CONF_REG               (0x85)
#define CMD_WRITE_VOL_CONF_REG              (0x81)
#define CMD_READ_NONVOL_CONF_REG            (0xB5)

#define DUMMY_CNT                           (0xa)


typedef struct {
    uint8_t manf_id;
    uint8_t mem_type;
    uint8_t mem_cap;
} n25q_id_t;

void flash_n25q_init(uint32_t controller, uint16_t clk_div);
void flash_n25q_set_spi_mode(uint8_t mode);
void flash_n25q_set_spi_controller(uint32_t controller);
n25q_id_t flash_n25q_read_id(uint8_t cmd);
void flash_n25q_write_enable(uint8_t en);
uint8_t flash_n25q_read_reg(uint8_t cmd);
void flash_n25q_write_reg(uint8_t cmd, uint8_t data);
uint8_t flash_n25q_read_status_reg();
uint8_t flash_n25q_is_busy();
void flash_n25q_read(uint8_t data[], uint32_t len, uint32_t addr);
void flash_n25q_subsector_erase(uint32_t subsector);
void flash_n25q_sector_erase(uint32_t sector);
void flash_n25q_page_program(uint8_t data[], uint32_t len, uint32_t page);
void flash_n25q_enable_quad_mode(uint8_t en);
void flash_n25q_set_dummy_clock_cycles(uint8_t num);

#endif
