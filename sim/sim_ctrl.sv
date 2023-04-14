 /*                                                                      
 Copyright 2021 Blue Liang, liangkangnan@163.com
                                                                         
 Licensed under the Apache License, Version 2.0 (the "License");         
 you may not use this file except in compliance with the License.        
 You may obtain a copy of the License at                                 
                                                                         
     http://www.apache.org/licenses/LICENSE-2.0                          
                                                                         
 Unless required by applicable law or agreed to in writing, software    
 distributed under the License is distributed on an "AS IS" BASIS,       
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and     
 limitations under the License.                                          
 */

`define REG_CTRL  0
`define REG_PRINT 4
`define REG_DUMP  8

module sim_ctrl(
    input  logic       clk_i,
    input  logic       rst_ni,

    output logic       dump_wave_en_o,

    input  logic       req_i,
    output logic       gnt_o,
    input  logic[31:0] addr_i,
    input  logic       we_i,
    input  logic[3:0]  be_i,
    input  logic[31:0] wdata_i,
    output logic       rvalid_o,
    output logic[31:0] rdata_o
    );

    logic[7:0] reg_addr;

    assign reg_addr = {addr_i[7:2], 2'b0};
    assign gnt_o = req_i;

    assign rdata_o = 32'h0;

    always_ff @ (posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            dump_wave_en_o <= 1'b0;
            rvalid_o <= 1'b0;
        end else begin
            rvalid_o <= req_i;
            if (req_i & we_i) begin
                case (reg_addr)
                    `REG_CTRL: begin
                        if (be_i[0] & wdata_i[0]) begin
                            $display("sim finish...");
                            $finish;
                        end
                    end

                    `REG_PRINT: begin
                        if (be_i[0]) begin
                            $display("%c", wdata_i[7:0]);
                        end
                    end

                    `REG_DUMP: begin
                        if (be_i[0] & wdata_i[0]) begin
                            dump_wave_en_o <= 1'b1;
                        end else if (be_i[0] & (!wdata_i[0])) begin
                            dump_wave_en_o <= 1'b0;
                        end
                    end

                    default: ;
                endcase
            end
        end
    end

endmodule
