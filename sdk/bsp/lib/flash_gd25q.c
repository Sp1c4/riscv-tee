#include <stdint.h>

#include "../../bsp/include/spi.h"
#include "../../bsp/include/rvic.h"
#include "../../bsp/include/utils.h"
#include "../../bsp/include/flash_gd25q.h"

/* GD25Q127特点:
 * 1.总共128Mb大小，即16MB
 * 2.总共64K页，每页大小256字节
 * 3.总共4K扇区，每个扇区大小为4K字节，16页
 * 4.总共256个block，每个block大小为64K字节，16个扇区
 * 5.擦除的最小单位是扇区，编程(写)的最小单位是页，读的最小单位是字节
 */

static uint8_t current_spi_mode;
static uint32_t spi_base_addr;

void flash_gd25q_init(uint32_t controller, uint16_t clk_div)
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

void flash_gd25q_set_spi_mode(uint8_t mode)
{
    current_spi_mode = mode;
}

void flash_gd25q_set_spi_controller(uint32_t controller)
{
    spi_base_addr = controller;
}

// 写使能
// 擦除或者编程或者写寄存器之前必须先发送写使能命令
void flash_gd25q_write_enable(uint8_t en)
{
    uint8_t cmd;

    if (en)
        cmd = CMD_WRITE_ENABLE;
    else
        cmd = CMD_WRITE_DISABLE;

    spi_set_spi_mode(spi_base_addr, SPI_MODE_STANDARD);

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_set_ss_level(spi_base_addr, 1);

    spi_set_spi_mode(spi_base_addr, current_spi_mode);
}

// 读寄存器
uint8_t flash_gd25q_read_reg(uint8_t cmd)
{
    uint8_t data;

    spi_set_spi_mode(spi_base_addr, SPI_MODE_STANDARD);

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_read_bytes(spi_base_addr, &data, 1);
    spi_set_ss_level(spi_base_addr, 1);

    spi_set_spi_mode(spi_base_addr, current_spi_mode);

    return data;
}

// 写寄存器
void flash_gd25q_write_reg(uint8_t cmd, uint8_t data)
{
    spi_set_spi_mode(spi_base_addr, SPI_MODE_STANDARD);

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_write_bytes(spi_base_addr, &data, 1);
    spi_set_ss_level(spi_base_addr, 1);

    spi_set_spi_mode(spi_base_addr, current_spi_mode);
}

// 是否正在擦除或者编程
uint8_t flash_gd25q_is_busy()
{
    if (flash_gd25q_read_reg(CMD_READ_STATUS_REG1) & 0x1)
        return 1;
    else
        return 0;
}

// 读数据
// addr: 0, 1, 2, ...
void flash_gd25q_read(uint8_t data[], uint32_t len, uint32_t addr)
{
    uint8_t cmd, i;
    uint8_t tran_addr[4];

    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;
    tran_addr[3] = 0x00;

    if (current_spi_mode == SPI_MODE_STANDARD) {
        cmd = CMD_READ;
        spi_set_ss_level(spi_base_addr, 0);
        spi_master_write_bytes(spi_base_addr, &cmd, 1);
        spi_master_write_bytes(spi_base_addr, tran_addr, 3);
        spi_master_read_bytes(spi_base_addr, data, len);
        spi_set_ss_level(spi_base_addr, 1);
    } else {
        cmd = CMD_QUAD_IO_FAST_READ;
        // 标准模式发送CMD
        spi_set_spi_mode(spi_base_addr, SPI_MODE_STANDARD);
        spi_set_ss_level(spi_base_addr, 0);
        spi_master_write_bytes(spi_base_addr, &cmd, 1);
        spi_set_spi_mode(spi_base_addr, SPI_MODE_QUAD);
        // QSPI模式发送ADDR
        spi_master_write_bytes(spi_base_addr, tran_addr, 4);
        for (i = 0; i < (DUMMY_CNT >> 1); i++)
            spi_master_read_bytes(spi_base_addr, data, 1);
        spi_reset_rxfifo(spi_base_addr);
        spi_master_read_bytes(spi_base_addr, data, len);
        spi_set_ss_level(spi_base_addr, 1);
    }
}

static void sector_erase(uint8_t cmd, uint32_t addr)
{
    uint8_t tran_addr[3];

    flash_gd25q_write_enable(1);

    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;

    spi_set_spi_mode(spi_base_addr, SPI_MODE_STANDARD);

    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_write_bytes(spi_base_addr, tran_addr, 3);
    spi_set_ss_level(spi_base_addr, 1);

    while (flash_gd25q_is_busy());

    flash_gd25q_write_enable(0);

    spi_set_spi_mode(spi_base_addr, current_spi_mode);
}

// 扇区擦除
// sector，第几个扇区: 0 ~ N
void flash_gd25q_sector_erase(uint32_t sector)
{
    sector_erase(CMD_SECTOR_ERASE, GD25Q_SECTOR_TO_ADDR(sector));
}

// 页编程
// page，第几页: 0 ~ N
void flash_gd25q_page_program(uint8_t data[], uint32_t len, uint32_t page)
{
    uint8_t tran_addr[3];
    uint8_t cmd;
    uint32_t addr;

    flash_gd25q_write_enable(1);

    addr = GD25Q_PAGE_TO_ADDR(page);
    tran_addr[0] = (addr >> 16) & 0xff;
    tran_addr[1] = (addr >> 8)  & 0xff;
    tran_addr[2] = (addr >> 0)  & 0xff;

    if (current_spi_mode == SPI_MODE_STANDARD)
        cmd = CMD_PAGE_PROGRAM;
    else
        cmd = CMD_QUAD_PAGE_PROGRAM;

    spi_set_ss_level(spi_base_addr, 0);
    spi_set_spi_mode(spi_base_addr, SPI_MODE_STANDARD);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_write_bytes(spi_base_addr, tran_addr, 3);
    spi_set_spi_mode(spi_base_addr, current_spi_mode);
    spi_master_write_bytes(spi_base_addr, data, len);
    spi_set_ss_level(spi_base_addr, 1);

    while (flash_gd25q_is_busy());

    flash_gd25q_write_enable(0);
}

// 使能QUAD SPI模式
void flash_gd25q_enable_quad_mode(uint8_t en)
{
    uint8_t data;

    flash_gd25q_write_enable(1);

    data = flash_gd25q_read_reg(CMD_READ_STATUS_REG2);
    if (en) {
        data |= 1 << 1;
    } else {
        data &= ~(1 << 1);
    }
    flash_gd25q_write_reg(CMD_WRITE_STATUS_REG2, data);

    flash_gd25q_write_enable(0);
}

// 读flash ID
gd25q_id_t flash_gd25q_read_id()
{
    gd25q_id_t id;
    uint8_t cmd;
    uint8_t tran_addr[3];
    uint8_t data[2];

    tran_addr[0] = 0x00;
    tran_addr[1] = 0x00;
    tran_addr[2] = 0x00;

    cmd = CMD_READ_ID;
    spi_set_ss_level(spi_base_addr, 0);
    spi_master_write_bytes(spi_base_addr, &cmd, 1);
    spi_master_write_bytes(spi_base_addr, tran_addr, 3);
    spi_master_read_bytes(spi_base_addr, data, 2);
    spi_set_ss_level(spi_base_addr, 1);

    id.manf_id = data[0];
    id.dev_id = data[1];

    return id;
}
