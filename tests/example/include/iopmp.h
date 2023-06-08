#ifndef _IOPMP_H_
#define _IOPMP_H_

#define IOPMP_BASE      (0x60000000)
#define IOPMP_GPIO      (IOPMP_BASE + (0x04))
#define IOPMP_REG(addr) (*((volatile uint32_t *)addr))
#endif