#include <stdint.h>

#include "../../bsp/include/spi.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/flash_n25q.h"

/* N25Q064特点:
 * 1.总共64Mb大小，即8MB
 * 2.总共128个扇区，每个扇区大小为64KB
 * 3.总共2048个子扇区，每个子扇区大小为4KB
 * 4.总共37768页，每页大小为256B
 * 5.擦除的最小单位是子扇区，编程(写)的最小单位是页，读的最小单位是字节
 */

static uint8_t current_spi_mode;
static uint32_t spi_base_addr;


void flash_n25q_init(uint32_t controller, uint16_t clk_div)
{
    spi_base_addr = controller;

    spi_set_clk_div(spi_base_addr, clk_div);
    spi_set_role_mode(spi_base_addr, SPI_ROLE_MODE_MASTER);
    spi_set_spi_mode(spi_base_addr, SPI_MODE_STANDARD);
    spi_set_cp_mode(spi_base_addr, SPI_CPOL_0_CPHA_0);
    spi_set_msb_first(spi_base_addr);
    spi_master_set_ss_delay(spi_base_addr, 1);
    spi_set_ss_level(spi_base_addr, 1);
    spi_set_ss_ctrl_by_sw(spi_base_addr, 1);
    spi_set_enable(spi_base_addr, 1);
}

void flash_n25q_set_spi_mode(uint8_t mode)
{
    current_spi_mode = mode;
}

void flash_n25q_set_spi_controller(uint32_t controller)
{
    spi_base_addr = controller;
}

// 写使能
// 擦除或者编程或者写寄存器之前必须先发送写使能命令
void flash_n25q_write_enable(uint8_t en)
{
    uint8_t cmd;

    if (en)
        cmd = CMD_WRITE_ENABLE;
    else
        cmd = CMD_WRITE_DISABLE;

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_set_ss_level(spi_base_addr, 1);
}

// 读寄存器
uint8_t flash_n25q_read_reg(uint8_t cmd)
{
    uint8_t data;

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_read_bytes(spi_base_addr, &data, 1);
    spi_set_ss_level(spi_base_addr, 1);

    return data;
}

// 写寄存器
void flash_n25q_write_reg(uint8_t cmd, uint8_t data)
{
    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_write_bytes(spi_base_addr, &data, 1);
    spi_set_ss_level(spi_base_addr, 1);
}

// 读状态寄存器
uint8_t flash_n25q_read_status_reg()
{
    uint8_t data;

    data = flash_n25q_read_reg(CMD_READ_STATUS_REG);

    return data;
}

// 是否正在擦除或者编程
uint8_t flash_n25q_is_busy()
{
    if (flash_n25q_read_status_reg() & 0x1)
        return 1;
    else
        return 0;
}

// 读数据
// addr: 0, 1, 2, ...
void flash_n25q_read(uint8_t data[], uint32_t len, uint32_t addr)
{
    uint8_t cmd, i;
    uint8_t tran_addr[3];

    if (current_spi_mode == SPI_MODE_STANDARD)
        cmd = CMD_READ;
    else
        cmd = CMD_FAST_READ;

    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_write_bytes(spi_base_addr, tran_addr, 3);
    if (current_spi_mode != SPI_MODE_STANDARD) {
        for (i = 0; i < (DUMMY_CNT >> 1); i++)
            spi_master_read_bytes(spi_base_addr, data, 1);
        spi_reset_rxfifo(spi_base_addr);
    }
    spi_master_read_bytes(spi_base_addr, data, len);
    spi_set_ss_level(spi_base_addr, 1);
}

static void sector_erase(uint8_t cmd, uint32_t addr)
{
    uint8_t tran_addr[3];

    flash_n25q_write_enable(1);

    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_write_bytes(spi_base_addr, tran_addr, 3);
    spi_set_ss_level(spi_base_addr, 1);

    while (flash_n25q_is_busy());

    flash_n25q_write_enable(0);
}

// 子扇区擦除
// subsector，第几个子扇区: 0 ~ N
void flash_n25q_subsector_erase(uint32_t subsector)
{
    sector_erase(CMD_SUBSECTOR_ERASE, N25Q_SUBSECTOR_TO_ADDR(subsector));
}

// 扇区擦除
// sector，第几个扇区: 0 ~ N
void flash_n25q_sector_erase(uint32_t sector)
{
    sector_erase(CMD_SECTOR_ERASE, N25Q_SECTOR_TO_ADDR(sector));
}

// 页编程
// page，第几页: 0 ~ N
void flash_n25q_page_program(uint8_t data[], uint32_t len, uint32_t page)
{
    uint8_t tran_addr[3];
    uint8_t cmd;
    uint32_t addr;

    flash_n25q_write_enable(1);

    addr = N25Q_PAGE_TO_ADDR(page);
    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;

    cmd = CMD_PAGE_PROGRAM;

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_write_bytes(spi_base_addr, tran_addr, 3);
    spi_master_write_bytes(spi_base_addr, data, len);
    spi_set_ss_level(spi_base_addr, 1);

    while (flash_n25q_is_busy());

    flash_n25q_write_enable(0);
}

// 使能QUAD SPI模式
void flash_n25q_enable_quad_mode(uint8_t en)
{
    uint8_t data;

    flash_n25q_write_enable(1);

    data = flash_n25q_read_reg(CMD_READ_ENHANCED_VOL_CONF_REG);
    if (en) {
        data &= ~(1 << 7);
        data |= 1 << 6;
    } else {
        data |= 0x3 << 6;
    }
    flash_n25q_write_reg(CMD_WRITE_ENHANCED_VOL_CONF_REG, data);

    flash_n25q_write_enable(0);
}

// 设置n25q dummy cycles
void flash_n25q_set_dummy_clock_cycles(uint8_t num)
{
    uint8_t data;

    flash_n25q_write_enable(1);

    data = flash_n25q_read_reg(CMD_READ_VOL_CONF_REG);
    data &= ~(0xf << 4);
    data |= num << 4;
    flash_n25q_write_reg(CMD_WRITE_VOL_CONF_REG, data);

    flash_n25q_write_enable(0);
}

// 读flash ID
n25q_id_t flash_n25q_read_id(uint8_t cmd)
{
    n25q_id_t id;
    uint8_t data[3];

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_read_bytes(spi_base_addr, data, 3);
    spi_set_ss_level(spi_base_addr, 1);

    id.manf_id = data[0];
    id.mem_type = data[1];
    id.mem_cap = data[2];

    return id;
}
