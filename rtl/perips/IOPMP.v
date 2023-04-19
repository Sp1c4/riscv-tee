`include "../core/defines.v"

module IOPMP(
    input wire clk,
	input wire rst,

    input wire we_i,
    input wire[31:0] addr_i,
    input wire[31:0] data_i,
    output reg[31:0] data_o,

    output  reg [`MemAddrBus] rib_ex_addr_o,  
    input   wire[`MemBus]   rib_ex_data_i,  
    output  reg [`MemBus]   rib_ex_data_o, 
    output  reg  rib_ex_req_o,   
    output  reg  rib_ex_we_o,

    input   wire[`MemAddrBus]    core0_ex_addr_o,
    output  reg [`MemBus]    core0_ex_data_i,
    input   wire[`MemBus]    core0_ex_data_o,
    input   wire core0_ex_req_o,
    input   wire core0_ex_we_o  


);
reg [7:0] iopmpcfg0 = 8'b00000111;
reg [7:0] iopmpcfg1 = 8'b00000111;
reg [7:0] iopmpcfg2 = 8'b00000111;
reg [7:0] iopmpcfg3 = 8'b00000111;
reg [31:0] iopmpaddr0 = 32'h20000000;
reg [31:0] iopmpaddr1 = 32'h30000000;
reg [31:0] iopmpaddr2 = 32'h40000000;
reg [31:0] iopmpaddr3 = 32'h50000000;
always@(posedge clk or negedge rst) begin
    if(~rst) begin
        iopmpcfg0 <= 8'b00000111;
        iopmpcfg1 <= 8'b00000111;
        iopmpcfg2 <= 8'b00000111;
        iopmpcfg3 <= 8'b00000111;
        iopmpaddr0 <= 32'h20000000;
        iopmpaddr1 <= 32'h30000000;
        iopmpaddr2 <= 32'h40000000;
        iopmpaddr3 <= 32'h50000000;
    end 
    else if(we_i == 1'b1) begin
        case (addr_i[3:0])
            iopmpaddr0[31:28]:begin
                iopmpcfg0 <= data_i[7:0];
            end
            iopmpaddr1[31:28]:begin
                iopmpcfg1 <= data_i[7:0];
            end
            iopmpaddr2[31:28]:begin
                iopmpcfg2 <= data_i[7:0];
            end
            iopmpaddr3[31:28]:begin
                iopmpcfg3 <= data_i[7:0];
            end
            default:begin
            end
        endcase
    end

end
always@(*) begin
    case(core0_ex_addr_o[31:28])
        iopmpaddr0[31:28]:begin
            if(iopmpcfg0[2:0] == 3'b111) begin
                rib_ex_addr_o   = core0_ex_addr_o;
                core0_ex_data_i = rib_ex_data_i;
                rib_ex_data_o   = core0_ex_data_o;
                rib_ex_req_o    = core0_ex_req_o;
                rib_ex_we_o     = core0_ex_we_o;
            end
        end
        iopmpaddr1[31:28]:begin
            if(iopmpcfg1[2:0] == 3'b111) begin
                rib_ex_addr_o   = core0_ex_addr_o;
                core0_ex_data_i = rib_ex_data_i;
                rib_ex_data_o   = core0_ex_data_o;
                rib_ex_req_o    = core0_ex_req_o;
                rib_ex_we_o     = core0_ex_we_o;
            end
        end
        iopmpaddr2[31:28]:begin
            if(iopmpcfg2[2:0] == 3'b111) begin
                rib_ex_addr_o   = core0_ex_addr_o;
                core0_ex_data_i = rib_ex_data_i;
                rib_ex_data_o   = core0_ex_data_o;
                rib_ex_req_o    = core0_ex_req_o;
                rib_ex_we_o     = core0_ex_we_o;
            end
        end
        iopmpaddr3[31:28]:begin
            if(iopmpcfg3[2:0] == 3'b111) begin
                rib_ex_addr_o   = core0_ex_addr_o;
                core0_ex_data_i = rib_ex_data_i;
                rib_ex_data_o   = core0_ex_data_o;
                rib_ex_req_o    = core0_ex_req_o;
                rib_ex_we_o     = core0_ex_we_o;
            end
        end
        default:begin
        end
    endcase
    
end

endmodule