#include <stdint.h>
#include "../../bsp/include/utils.h"
#include "../../bsp/include/flash_ctrl.h"

int main()
{
    uint32_t data;

    flash_ctrl_sector_erase(0x0);
    flash_ctrl_write(0x00, 0x12345678);
    flash_ctrl_read(0x00, &data);

    if (data != 0x12345678)
        return -1;

    return 0;
}
