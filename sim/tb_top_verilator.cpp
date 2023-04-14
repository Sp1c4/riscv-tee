#include "svdpi.h"
#include "Vtb_top_verilator__Dpi.h"
#include "Vtb_top_verilator.h"
#include "verilated_vcd_c.h"
#include "verilated.h"

#include <iostream>
#include <iomanip>
#include <fstream>
#include <exception>
#include <cstdio>
#include <cstdint>
#include <cerrno>

double sc_time_stamp();

static vluint64_t t = 0;
Vtb_top_verilator *top;

int main(int argc, char **argv, char **env)
{
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    top = new Vtb_top_verilator();

#ifdef VCD_TRACE
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("verilator_tb.vcd");
#endif

    top->clk_i          = 0;
    top->rst_ni         = 0;

    top->eval();

    while (!Verilated::gotFinish()) {
        if (t < 50)
            top->rst_ni         = 1;
        else if (t < 100)
            top->rst_ni         = 0;
        else if (t < 150)
            top->rst_ni         = 1;

        top->clk_i = !top->clk_i;
        top->eval();

#ifdef VCD_TRACE
        if (top->dump_wave_en_o)
            tfp->dump(t);
#endif

        t += 5;
    }

#ifdef VCD_TRACE
    tfp->close();
#endif

    delete top;
    exit(0);
}

double sc_time_stamp()
{
    return t;
}
