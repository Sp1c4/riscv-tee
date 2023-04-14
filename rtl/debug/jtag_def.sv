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


`define DbgVersion013       4'h2
`define ProgBufSize         5'h8
`define DataCount           4'h1
`define HaltAddress         64'h800
`define ResumeAddress       `HaltAddress + 4
`define ExceptionAddress    `HaltAddress + 8
`define DataBaseAddr        12'h380
`define AbstCmdBaseAddr     12'h338
`define AbstCmdCount        12'd10
`define ProgbufBaseAddr     `AbstCmdBaseAddr + (4 * `AbstCmdCount)

// dmi op
`define DMI_OP_NOP          2'b00
`define DMI_OP_READ         2'b01
`define DMI_OP_WRITE        2'b10

// DM regs addr
`define Data0               7'h04
`define Data1               7'h05
`define Data2               7'h06
`define Data3               7'h07
`define Data4               7'h08
`define DMControl           7'h10
`define DMStatus            7'h11
`define Hartinfo            7'h12
`define AbstractCS          7'h16
`define Command             7'h17
`define AbstractAuto        7'h18
`define ProgBuf0            7'h20
`define ProgBuf1            7'h21
`define ProgBuf2            7'h22
`define ProgBuf3            7'h23
`define ProgBuf4            7'h24
`define ProgBuf5            7'h25
`define ProgBuf6            7'h26
`define ProgBuf7            7'h27
`define ProgBuf8            7'h28
`define ProgBuf9            7'h29
`define ProgBuf10           7'h2A
`define ProgBuf11           7'h2B
`define ProgBuf12           7'h2C
`define ProgBuf13           7'h2D
`define ProgBuf14           7'h2E
`define ProgBuf15           7'h2F
`define SBAddress3          7'h37
`define SBCS                7'h38
`define SBAddress0          7'h39
`define SBAddress1          7'h3A
`define SBAddress2          7'h3B
`define SBData0             7'h3C
`define SBData1             7'h3D
`define SBData2             7'h3E
`define SBData3             7'h3F
`define HaltSum0            7'h40
`define HaltSum1            7'h13

// dmstatus bit index
`define Impebreak           22
`define Allhavereset        19
`define Anyhavereset        18
`define Allresumeack        17
`define Anyresumeack        16
`define Allnonexistent      15
`define Anynonexistent      14
`define Allunavail          13
`define Anyunavail          12
`define Allrunning          11
`define Anyrunning          10
`define Allhalted           9
`define Anyhalted           8
`define Authenticated       7
`define Authbusy            6
`define Hasresethaltreq     5
`define Confstrptrvalid     4
`define Version             3:0

// dmcontrol bit index
`define Haltreq             31
`define Resumereq           30
`define Hartreset           29
`define Ackhavereset        28
`define Hasel               26
`define Hartsello           25:16
`define Hartselhi           15:6
`define Setresethaltreq     3
`define Clrresethaltreq     2
`define Ndmreset            1
`define Dmactive            0

// abstractcs bit index
`define Progbufsize         28:24
`define Busy                12
`define Cmderr              10:8
`define Datacount           3:0

// abstract command access register bit index
`define Cmdtype             31:24
`define Aarsize             22:20
`define Aarpostincrement    19
`define Postexec            18
`define Transfer            17
`define Write               16
`define Regno               15:0

// sbcs bit index
`define Sbversion           31:29
`define Sbbusyerror         22
`define Sbbusy              21
`define Sbreadonaddr        20
`define Sbaccess            19:17
`define Sbautoincrement     16
`define Sbreadondata        15
`define Sberror             14:12
`define Sbasize             11:5
`define Sbaccess128         4
`define Sbaccess64          3
`define Sbaccess32          2
`define Sbaccess16          1
`define Sbaccess8           0

// abstractauto
`define AutoexecData        11:0
`define AutoexecProgbuf     31:16

`define CSR_CYCLE       12'hc00
`define CSR_CYCLEH      12'hc80
`define CSR_MTVEC       12'h305
`define CSR_MCAUSE      12'h342
`define CSR_MEPC        12'h341
`define CSR_MIE         12'h304
`define CSR_MSTATUS     12'h300
`define CSR_MSCRATCH    12'h340
`define CSR_MHARTID     12'hF14
`define CSR_DCSR        12'h7b0
`define CSR_DPC         12'h7b1
`define CSR_DSCRATCH0   12'h7b2
`define CSR_DSCRATCH1   12'h7b3

