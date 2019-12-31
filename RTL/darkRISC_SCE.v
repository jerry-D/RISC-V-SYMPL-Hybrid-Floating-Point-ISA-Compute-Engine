//darkRISC_SCE.v
//
// Author:  Jerry D. Harthcock
// Version:  1.01  December 30, 2019
// Copyright (C) 2019.  All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                    //
//                                                    Open-Source                                                     //
//                            SYMPL 64-Bit Universal Floating-point ISA Compute Engine and                            //
//                                   Fused Universal Neural Network (FuNN) eNNgine                                    //
//                                    Evaluation and Product Development License                                      //
//                                                                                                                    //
//                                                                                                                    //
// Open-source means:  this source code and this instruction set ("this IP") may be freely downloaded, copied,        //
// modified, distributed and used in accordance with the terms and conditons of the licenses provided herein.         //
//                                                                                                                    //
// Provided that you comply with all the terms and conditions set forth herein, Jerry D. Harthcock ("licensor"),      //
// the original author and exclusive copyright owner of this SYMPL 64-Bit Universal Floating-point ISA Compute Engine //
// and Fused Universal Neural Network (FuNN) eNNgine, including related development software ("this IP"), hereby      //
// grants recipient of this IP ("licensee"), a world-wide, paid-up, non-exclusive license to implement this IP        //
// within the programmable fabric of Xilinx Kintex Ultra and Kintex Ultra+ brand FPGAs--only--and used only for the   //
// purposes of evaluation, education, and development of end products and related development tools.  Furthermore,    //
// limited to the purposes of prototyping, evaluation, characterization and testing of implementations in a hard,     //
// custom or semi-custom ASIC, any university or institution of higher education may have their implementation of     //
// this IP produced for said limited purposes at any foundary of their choosing provided that such prototypes do      //
// not ever wind up in commercial circulation, with this license extending to such foundary and is in connection      //
// with said academic pursuit and under the supervision of said university or institution of higher education.        //
//                                                                                                                    //
// Any copying, distribution, customization, modification, or derivative work of this IP must include an exact copy   //
// of this license and original copyright notice at the very top of each source file and any derived netlist, and,    //
// in the case of binaries, a printed copy of this license and/or a text format copy in a separate file distributed   //
// with said netlists or binary files having the file name, "LICENSE.txt".  You, the licensee, also agree not to      //
// remove any copyright notices from any source file covered or distributed under this Evaluation and Product         //
// Development License.                                                                                               //
//                                                                                                                    //
// LICENSOR DOES NOT WARRANT OR GUARANTEE THAT YOUR USE OF THIS IP WILL NOT INFRINGE THE RIGHTS OF OTHERS OR          //
// THAT IT IS SUITABLE OR FIT FOR ANY PURPOSE AND THAT YOU, THE LICENSEE, AGREE TO HOLD LICENSOR HARMLESS FROM        //
// ANY CLAIM BROUGHT BY YOU OR ANY THIRD PARTY FOR YOUR SUCH USE.                                                     //
//                                                                                                                    //
// Licensor reserves all his rights, including, but in no way limited to, the right to change or modify the terms     //
// and conditions of this Evaluation and Product Development License anytime without notice of any kind to anyone.    //
// By using this IP for any purpose, licensee agrees to all the terms and conditions set forth in this Evaluation     //
// and Product Development License.                                                                                   //
//                                                                                                                    //
// This Evaluation and Product Development License does not include the right to sell products that incorporate       //
// this IP or any IP derived from this IP. If you would like to obtain such a license, please contact Licensor.       //
//                                                                                                                    //
// Licensor can be contacted at:  SYMPL.gpu@gmail.com or Jerry.Harthcock@gmail.com                                    //
//                                                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100ps

//`define RISC_V_HAS_THREE_PORT_DATA_RAM

module darkRISC_SCE (
    CLK,
    RESET,
    READY_q1,
    SCE_all_done //all SCEs are done
    );    
input CLK;
input RESET;
input READY_q1;
output SCE_all_done;
    
wire RISC_V_IRQ;
wire [31:0] RISC_V_instr;    
wire [31:0] RISC_V_paddrs;
wire [31:0] RISC_V_rddata;
wire [31:0] RISC_V_wrdata;
wire [31:0] RISC_V_daddrs;
wire RISC_V_WR;
wire RISC_V_RD;

wire [2:0] RISC_V_SIZE;
wire SCEdone_0;
wire SCE_IRQ_0;
wire SCEdone_1;
wire SCE_IRQ_1;
wire RISC_V_cancel;
wire [31:0] x31; 
wire [31:0] x30; 
wire [31:0] x29; 
wire [31:0] x28;
wire [31:0] x27;
reg [63:0] SCErddata; 
wire [63:0] SCErddata_0; 
wire [63:0] SCErddata_1; 
wire [63:0] UFMArddata; 
reg [31:0] SCEstatus;
wire [7:0] SCEstatus_0;
wire [7:0] SCEstatus_1;
wire [7:0] UFMAstatus;
wire SCE_all_done;
//wire monRDreq;
wire [15:0] targetSCErdSel;

wire XPULL_q2;
wire XPUSH_q1;
wire XPUSHD_q1;

wire [63:0] RAMwrdata;
wire [31:0] RAMwraddrs;
wire [2:0]  RAMwrsize;
wire [31:0] RAMrdaddrsA;
wire [31:0] RAMrdaddrsB;
wire [2:0]  RAMrdsize;
wire [63:0] RAMrddataA;
wire [63:0] RAMrddataB;
reg [31:0] XPULL_write_addrs_q2;
wire [2:0] monRWsize_q1;
wire [2:0] monRWsize_q2;
wire SigA_q1;
wire SigD_q2;

assign RAMwrdata =  XPULL_q2 ? SCErddata : {32'b0, RISC_V_wrdata}; 
assign RAMwraddrs = XPULL_q2 ? XPULL_write_addrs_q2 : RISC_V_daddrs;
assign RAMwrsize =  XPULL_q2 ? monRWsize_q2 : RISC_V_SIZE;
assign RAMrdaddrsA = (XPUSH_q1||XPUSHD_q1) ? x30  : RISC_V_daddrs; 
assign RAMrdaddrsB = XPUSHD_q1 ? x27 : 0; 
assign RAMrdsize =  (XPUSH_q1||XPUSHD_q1) ? monRWsize_q1 : RISC_V_SIZE; 
assign RISC_V_rddata = RAMrddataA[31:0];
assign targetSCErdSel = x28[15:0];

assign RISC_V_IRQ = 1'b0;
assign SCE_IRQ_0 = 1'b0;
assign SCE_IRQ_1 = 1'b0;
assign SCE_all_done = SCEdone_0 && SCEdone_1;

assign UFMArddata = 0;
assign UFMAstatus = 0;

always @(posedge CLK) XPULL_write_addrs_q2 <= x30;

always @(*)
    casex(targetSCErdSel)
        16'b1xxxxxxxxxxxxxxx,
        16'b01xxxxxxxxxxxxxx,
        16'b001xxxxxxxxxxxxx,
        16'b0001xxxxxxxxxxxx,
        16'b00001xxxxxxxxxxx,
        16'b000001xxxxxxxxxx,
        16'b0000001xxxxxxxxx,
        16'b00000001xxxxxxxx,
        16'b000000001xxxxxxx,
        16'b0000000001xxxxxx,
        16'b00000000001xxxxx,
        16'b000000000001xxxx,
        16'b0000000000001xxx,
        16'b00000000000001xx : begin
                                  SCEstatus = {24'b0, UFMAstatus};
                                  SCErddata = UFMArddata;
                               end   
        16'b000000000000001x : begin
                                  SCEstatus = {15'b0, SCEdone_1, 8'b0, SCEstatus_1};
                                  SCErddata = SCErddata_1;
                               end   
        16'b0000000000000001 : begin
                                  SCEstatus = {15'b0, SCEdone_0, 8'b0, SCEstatus_0};
                                  SCErddata = SCErddata_0;
                               end   
                     default : begin
                                  SCEstatus = 0;
                                  SCErddata = 0;
                               end   
    endcase


                     
darkriscv_mod darkRISC(
    .CLK  (CLK),           
    .RES  (RESET),         
    .HLT  (~READY_q1 ),    // RISC_V halt input (active high)
    .IREQ (RISC_V_IRQ  ),  // RISC_V interrupt request
    .IDATA(RISC_V_instr),  // RISC_V prog instruction bus
    .IADDR(RISC_V_paddrs), // RISC_V instruction addr bus
    .DATAI(RISC_V_rddata[31:0]), // RISC_V data bus (input)
    .DATAO(RISC_V_wrdata[31:0]), // RISC_V data bus (output)
    .DADDR(RISC_V_daddrs), // RISC_V data addr bus
    .WR   (RISC_V_WR),     // RISC_V data write enable
    .RD   (RISC_V_RD),     // RISC_V data read enable 
//---------------------------------------------- JDH ----------------------------------------------|    
    .SIZE (RISC_V_SIZE),         // RISC_V data transaction size                                   |
    .RISC_V_cancel(RISC_V_cancel), //cancel currently fetched and registered RISC_V instruction    |
    .x31(x31),             // RISC-V x31 register                                                  |
    .x30(x30),             // RISC-V x30 register                                                  |
    .x29(x29),             // RISC-V x29 register                                                  |
    .x28(x28),             // RISC-V x28 register                                                  |
    .x27(x27),             // RISC-V x27 register                                                  |
    .XPULL_q2 (XPULL_q2 ), //                                                                      |
    .XPUSH_q1 (XPUSH_q1 ), //                                                                      |
    .XPUSHD_q1(XPUSHD_q1), //                                                                      |
    .monRWsize_q1 (monRWsize_q1), //                                                               |
    .monRWsize_q2 (monRWsize_q2), //                                                               |
    .SigA_q1  (SigA_q1), //                                                                        |
    .SigD_q2  (SigD_q2), //                                                                        |
    .SCErddata(SCErddata), // read data from SCE                                                   |
    .SCEstatus(SCEstatus)  // SCE status bits                                                      |
//-------------------------------------------------------------------------------------------------|    
);

`define PCWIDTH 20    // SCE program counter width in bits
`define PSIZE 13      // SCE (minimum of 13 = 64k bytes) program memory size in dwords 17-bit address = 128k x 64bit = 1M bytes of program memory
`define DSIZE 13      // SCE indirect data memory size 15-bit address = 32k x 64bit = 256k bytes of byte-addressable triport data RAM 
`define RPTSIZE 16    // SCE repeat counter size in bits
`define LPCNTRSIZE 16 // SCE loop counter size in bits

//-------------------------------------------------------------------------------------------------------------------------------------
// The following `defines pertain to the current SCE implementation that incorporates the Fused Universal Neural Network (FuNN) eNNgine
// Some of these are relatively expensive resource-wise, so if your application does not utilize this or that activation function, you might
// want to leave those undefined to conserve resources and improve simulation times.
//
// The demonstration included in this repository utilizes the operators actually defined below, so you may want to leave those alone.
//
// For more information on the FuNN eNNgine, refer to the information sheets included in this repository.
//-------------------------------------------------------------------------------------------------------------------------------------
`define SCE_HAS_PRNG               //H=7 human-readable floating-point pseudo-random number generator
`define SCE_HAS_FuNN               //Fused Universal Neural Network eNNgine
`define FuNN_Has_FromDecimalChar   //H=7 convertFromDecimalCharacter sequence (there are 32 of these in the FuNN eNNgine and one in the PRNG)
`define FuNN_Has_ToDecimalChar     //H=7 convertToDecimalCharacter sequence (there is one instance in the FuNN and one in the PRNG
//`define FuNN_Has_LReLU             //"Leaky" Rectified Linear Unit activation function
//`define FuNN_Has_ReLU              //Rectified Linear Unit activation function
//`define FuNN_Has_SQNL              //Square Non-Linearity activation function
//`define FuNN_Has_SoftPlus          //aka, Logistic, Sigmoid activation function
//`define FuNN_Has_SoftStep          //SoftStep activation function
//`define FuNN_Has_SQ_RFB            //Square Radial Basis Function activation function
`define FuNN_Has_TanH              //Hyperbolic Tangent activation function
//`define FuNN_Has_HardTan           //Hard Tangent activation function
//`define FuNN_Has_Gaussian          //Gaussian activation function
`define FuNN_Has_Exp               //Exponential function used for computing SoftMax activation function
`define FuNN_Has_HardMax           //HardMax activation function

//-------------------------------------------------------------------------------------------------------------------------------------
//The following `defines pertain to the fully pipelined IEEE754-2008 floating-point package, which is not presently included in this
//repository, as the FuNN eNNgine and the demo published here do not require them.  If you would like to evaluate the SCE with
//a complete IEEE754-2008 floating-point package, contact me.
//-------------------------------------------------------------------------------------------------------------------------------------
//`define SCE_HAS_FLOAT 
//`define SCE_HAS_INTEGER
//`define SCE_HAS_EXC_CAPTURE      // if you are not using alternate delayed exception handling, you probably should not define this
                                       
// ---- below are the largest of the floating point operators--if you will never use them and want to save resources
// ---- and increase clock rate as a result of reduced routing congestion, do not define them
//`define SCE_HAS_univFMA
//`define SCE_HAS_FMA
//`define SCE_HAS_TRIG
//`define SCE_HAS_POWER
//`define SCE_HAS_LOG
//`define SCE_HAS_EXP
//`define SCE_HAS_REMAINDER
//`define SCE_HAS_DIVISION
//`define SCE_HAS_MULTIPLICATION
//`define SCE_HAS_ADDITION
//`define SCE_HAS_SQRT
//`define SCE_HAS_BIN_DEC_CHAR        //fully pipelined H=20 convertToDecimalCharacter
//`define SCE_HAS_DEC_CHAR_BIN        //fully pipelined H=20 convertFromDecimalCharacter
//`define SCE_HAS_BIN_HEX_CHAR
//`define SCE_HAS_HEX_CHAR_BIN
//`define SCE_HAS_LOGB
//`define SCE_HAS_SCALEB
//`define SCE_HAS_NEXT
//`define SCE_HAS_COPY_ABS_NEGATE
//`define SCE_HAS_MIN_MAX
//`define SCE_HAS_RTOI
//`define SCE_HAS_CONV
//`define SCE_HAS_CTOI
//`define SCE_HAS_CFI

// SCE INTEGER DEFINES
//`define SCE_HAS_INTEGER       //if you want, you can exclude integer and logical operators (e.g., AND OR XOR ADD SUB MUL, etc.) from your SCE implementation
                                //Since the demo of the SCE with FuNN eNNgine does not require them, they are left undefined here
//`define SCE_HAS_INT_DIVIDE
//`define SCE_HAS_INT_MIN_MAX
//`define SCE_HAS_ENDI          //reverse endean-ness
//`define SCE_HAS_CONVERT_CHAR

SYMPL_COMPUTE_ENGINE_AI SCE_0(
   .CLK(CLK),
   .RESET_IN(RESET),

   .done(SCEdone_0),      
   .IRQ(SCE_IRQ_0),       

   .RISC_V_ready(READY_q1    ),
   .RISC_V_instr(RISC_V_instr),
   .RISC_V_cancel(RISC_V_cancel), //cancel currently fetched and registered RISC_V instruction  
   .x31(x31),             // RISC-V x31 register input to SCE
   .x30(x30),             // RISC-V x30 register input to SCE
   .x29(x29),             // RISC-V x29 register input to SCE
   .SCE_sel(x28[0]),      // compute engine select
   .RISC_V_RAMrddataA(RAMrddataA[63:0]), //(A-side) data to be written into SCE memory during XPUSH or XPUSHD execution
   .RISC_V_RAMrddataB(RAMrddataB[63:0]), //(B-side) data to be written into SCE memory during XPUSHDexecution

   .SCErddata(SCErddata_0), // read data from SCE
   .SCEstatus(SCEstatus_0) // status bits from SCE
   );

SYMPL_COMPUTE_ENGINE SCE_1(       //this SCE has no FuNN Engine
   .CLK(CLK),
   .RESET_IN(RESET),

   .done(SCEdone_1),      
   .IRQ(SCE_IRQ_1),       

   .RISC_V_ready(READY_q1    ),
   .RISC_V_instr(RISC_V_instr),
   .RISC_V_cancel(RISC_V_cancel), //cancel currently fetched and registered RISC_V instruction  
   .x31(x31),             // RISC-V x31 register input to SCE
   .x30(x30),             // RISC-V x30 register input to SCE
   .x29(x29),             // RISC-V x29 register input to SCE
   .SCE_sel(x28[1]),      // compute engine select
   .RISC_V_RAMrddataA(RAMrddataA[63:0]), //(A-side) data to be written into SCE memory during XPUSH or XPUSHD execution
   .RISC_V_RAMrddataB(RAMrddataB[63:0]), //(B-side) data to be written into SCE memory during XPUSHDexecution

   .SCErddata(SCErddata_1), // read data from SCE
   .SCEstatus(SCEstatus_1) // status bits from SCE
   );

RAM_func_dp #(.ADDRS_WIDTH(10), .DATA_WIDTH(32))    //8k bytes of program memory (2k locations of 4 bytes each)
    progSRAM(
    .CLK(CLK),
    .RESET(RESET),
    .wren(1'b0),
    .wraddrs(10'b0),
    .wrdata(32'b0),
    .rden(1'b1),
    .rdaddrs(RISC_V_paddrs[11:2]),
    .rddata(RISC_V_instr)
    );    

twoPortBlockRAMx64  #(.ADDRS_WIDTH(13)) //64K bytes  
    dataSRAM_A(                         //DATA SRAM
   .CLK       (CLK   ),
   .wren      ((RISC_V_WR || XPULL_q2) && (RAMwraddrs[31:16]==16'b0)),
   .wrsize    (RAMwrsize[1:0]),
   .wraddrs   (RAMwraddrs[15:0]),
   .wrdata    (RAMwrdata[63:0]),              
   .rdenA     (RAMrdaddrsA[31:16]==16'b0),
   .rdAsize   (RAMrdsize[1:0]),
   .rdaddrsA  (RAMrdaddrsA[15:0]),
   .rddataA   (RAMrddataA[63:0])
   ); 

`ifdef RISC_V_HAS_THREE_PORT_DATA_RAM
twoPortBlockRAMx64  #(.ADDRS_WIDTH(13)) //64K bytes  
    dataSRAM_B(                         //DATA SRAM
   .CLK       (CLK   ),
   .wren      ((RISC_V_WR || XPULL_q2) && (RAMwraddrs[31:16]==16'b0)),
   .wrsize    (RAMwrsize[1:0]),
   .wraddrs   (RAMwraddrs[15:0]),
   .wrdata    (RAMwrdata[63:0]),              
   .rdenA     (RAMrdaddrsB[31:16]==16'b0),
   .rdAsize   (RAMrdsize[1:0]),
   .rdaddrsA  (RAMrdaddrsB[15:0]),
   .rddataA   (RAMrddataB[63:0])
   ); 
`else
assign RAMrddataB = 0;
`endif
    


endmodule

