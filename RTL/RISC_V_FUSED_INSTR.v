//RISC_V_FUSED_INSTR.v
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


`timescale 1ns / 100ps

module RISC_V_FUSED_INSTR (
    CLK,
    RESET,
    risc_V_ready,
    risc_V_instr,
    risc_V_cancel,
    SCE_sel,
    XLQU_q1,   
    XLDU_q1,   
    XLWU_q1,   
    XLHU_q1,   
    XLBU_q1,   
    XSQ_q1,   
    XSD_q1,   
    XSW_q1,    
    XSH_q1,    
    XSB_q1,    
    XPUSH_q1,  
    XPULL_q1,  
    XPUSH_q0,  
    XPULL_q0,  
    XPUSHD_q1,
    XPUSHD_q0,
    XFRCBRK_q1,
    XCLRBRK_q1,
    XFRCRST_q1,
    XCLRRST_q1,
    XSSTEP_q1, 
    XSTATUS_q1,
    MREQ_q0
    );

input CLK;
input RESET;
input risc_V_ready;
input [31:0] risc_V_instr;
input risc_V_cancel;
input SCE_sel;

output XLQU_q1   ;      
output XLDU_q1   ;      
output XLWU_q1   ;  
output XLHU_q1   ;  
output XLBU_q1   ;  
output XSQ_q1    ;  
output XSD_q1    ;  
output XSW_q1    ;  
output XSH_q1    ;  
output XSB_q1    ;  
output XPUSH_q1  ;  
output XPULL_q1  ;  
output XPUSH_q0  ;  
output XPULL_q0  ;  
output XPUSHD_q1 ;  
output XPUSHD_q0 ;  
output XFRCBRK_q1;  
output XCLRBRK_q1;  
output XFRCRST_q1;  
output XCLRRST_q1;  
output XSSTEP_q1 ;  
output XSTATUS_q1; 
output MREQ_q0;

// alias (SCE gene-splice opcode registered decodes) 
reg XLQU_q1a   ;      
reg XLDU_q1a   ;      
reg XLWU_q1a   ;  
reg XLHU_q1a   ;  
reg XLBU_q1a   ;  
reg XSQ_q1a    ;  
reg XSD_q1a    ;  
reg XSW_q1a    ;  
reg XSH_q1a    ;  
reg XSB_q1a    ;  
reg XPUSH_q1a  ;  
reg XPULL_q1a  ;  
reg XPUSHD_q1a ; 
reg XFRCBRK_q1a;  
reg XCLRBRK_q1a;  
reg XFRCRST_q1a;  
reg XCLRRST_q1a;  
reg XSSTEP_q1a ;  
reg XSTATUS_q1a;
reg XORimm_0_q1a;   

// alias (SCE gene-splice opcode decodes) 
wire XLDU_q0   ;      
wire XLWU_q0   ;  
wire XLHU_q0   ;  
wire XLBU_q0   ;  
wire XSD_q0    ;  
wire XSW_q0    ;  
wire XSH_q0    ;  
wire XSB_q0    ;  
wire XPUSH_q0  ;  
wire XPULL_q0  ;  
wire XPUSHD_q0 ;
wire XFRCBRK_q0;  
wire XCLRBRK_q0;  
wire XFRCRST_q0;  
wire XCLRRST_q0;  
wire XSSTEP_q0 ;  
wire XSTATUS_q0; 
wire XORimm_0_q0;  //XOR immediate zero 
wire [4:0] srcR1_q0;
wire [4:0] destR_q0;
wire [11:0] immData_q0;
wire [6:0] opCode_q0;
wire [2:0] opType_q0;  
wire MREQ_q0;  //monitor request

wire XLQU_q1   ;
wire XLDU_q1   ;      
wire XLWU_q1   ;  
wire XLHU_q1   ;  
wire XLBU_q1   ;  
wire XSQ_q1    ;  
wire XSD_q1    ;  
wire XSW_q1    ;  
wire XSH_q1    ;  
wire XSB_q1    ;  
wire XPUSH_q1  ;  
wire XPULL_q1  ;  
wire XPUSHD_q1 ;  
wire XFRCBRK_q1;  
wire XCLRBRK_q1;  
wire XFRCRST_q1;  
wire XCLRRST_q1;  
wire XSSTEP_q1 ;  
wire XSTATUS_q1; 
wire XORimm_0_q1;   
                                                                      
assign immData_q0 = risc_V_instr[31:20]; //immediate data bit field
assign srcR1_q0 = risc_V_instr[19:15];  //source Rs1 bit field
assign opType_q0 = risc_V_instr[14:12];  //AND, OR, XOR, etc
assign destR_q0 = risc_V_instr[11:7];   //dest Rd bit field
assign opCode_q0 = risc_V_instr[6:0];    //op-code bit field
assign XORimm_0_q0 = (opCode_q0==7'b00100_11) && (opType_q0==3'b100) && (destR_q0==srcR1_q0) && ~|immData_q0 && SCE_sel;  //XORI Rd Rs1 #0  (Rd and Rs1 are same register)

assign XLQU_q0    = XORimm_0_q0 && (srcR1_q0==5'd01);  //loads {x31, x30} with 128-bit data from SCE memory pointed to by x29.  x28 one-hot specifies from which SCE. RV64I-only.
assign XLDU_q0    = XORimm_0_q0 && (srcR1_q0==5'd02);  //loads {x31, x30} with 64-bit data from SCE memory pointed to by x29.  x28 one-hot specifies from which SCE.
assign XLWU_q0    = XORimm_0_q0 && (srcR1_q0==5'd03);  //loads x30 with 32-bit data from SCE memory pointed to by x29.  x28 one-hot specifies from which SCE.
assign XLHU_q0    = XORimm_0_q0 && (srcR1_q0==5'd04);  //loads x30 with 16-bit data from SCE memory pointed to by x29, zero-extended.  x28 one-hot specifies from which SCE.
assign XLBU_q0    = XORimm_0_q0 && (srcR1_q0==5'd05);  //loads x30 with 8-bit data from SCE memory pointed to by x29, zero-extended.  x28 one-hot specifies from which SCE.
assign XSQ_q0     = XORimm_0_q0 && (srcR1_q0==5'd06);  //store the 128 bits of registers [{x31, x30}] into SCE memory space pointed to by [x29].  [x28] specifies to which SCE memory the transaction will take place, which can be up to 16 simultaneously. RV64I-only.
assign XSD_q0     = XORimm_0_q0 && (srcR1_q0==5'd07);  //store the 64 bits of registers [{x31, x30}] into SCE memory space pointed to by [x29].  [x28] specifies to which SCE memory the transaction will take place, which can be up to 16 simultaneously.
assign XSW_q0     = XORimm_0_q0 && (srcR1_q0==5'd08);  //store the 32 bits of register [x30] into SCE memory space pointed to by [x29].  [x28] specifies from which SCE memory the transaction will take place, which can be up to 16 simultaneously.
assign XSH_q0     = XORimm_0_q0 && (srcR1_q0==5'd09);  //store the lower 16 bits of [x30] into SCE memory space pointed to by [x29].  [x28] specifies from which SCE memory the transaction will take place, which can be up to 16 simultaneously.
assign XSB_q0     = XORimm_0_q0 && (srcR1_q0==5'd10);  //store the lower 8 bits of [x30] into SCE memory space pointed to by [x29].  [x28] specifies from which SCE memory the transaction will take place, which can be up to 16 simultaneously.
                                                       
assign XPUSH_q0   = XORimm_0_q0 && (srcR1_q0==5'd11);  //freeze PC                                                
                                                       //read the number of bytes specified by src size field x31[22:20] from RISC-V global memory address specified by x30 
                                                       //then automatically increment x30 by the amount (encoded location count 0=1, 1=2, 2=4, etc) specified in x31[26:24]
                                                       //then, if REPEAT amount specified in X31[11:0] is not already zero, decrement bit field X31[11:0] by 1
                                                       //if REPEAT amount is now zero, then freeze PC is released
                                                       //SCE executes this instruction and stores the data in its memory space at the location specified in RISC-V x29 using size specifier in x31[14:12]
                                                       //then automatically increments x29 by the amount (encoded location count 0=1, 1=2, 2=4, etc) specified in x31[18:16]
                                                       //x28 specifies to which SCE(s) memory space the data is to be written, which can be up to 16 simultaneously
                                                       
assign XPULL_q0   = XORimm_0_q0 && (srcR1_q0==5'd12);  //freeze PC
                                                       //read the number of bytes specified by src size filed x31[14:12] from SCE memory address specified by x29 
                                                       //then automatically increment x29 by the amount (encoded location count 0=1, 1=2, 2=4, etc) specified in x31[18:16]
                                                       //then, if REPEAT amount specified in X31[11:0] is not already zero, decrement bit field X31[11:0] by 1
                                                       //if REPEAT amount is now zero, then freeze PC is released
                                                       //RISC-V executes this instruction and stores the data in its memory space at the location specified in RISC-V x30 using size specifier in x31[22:20]
                                                       //then automatically increments x30 by the amount (encoded location count 0=1, 1=2, 2=4, etc) specified in x31[26:24]
                                                       //the one-hot value in x28 specifies from which SCE(s) memory space the data is to be read
                                                       
assign XPUSHD_q0  = XORimm_0_q0 && (srcR1_q0==5'd13);  //same as XPUSH, except pushes dual operands read from RISC-V three-port data RAM (if implemented) into specified SCE operator requiring dual operands
assign XFRCBRK_q0 = XORimm_0_q0 && (srcR1_q0==5'd14);  //one-shot sets force-break bit in selected SCE break control register.  Lower 16 bits of x28 specifies to which SCE the action applies, which can be all 16.
assign XCLRBRK_q0 = XORimm_0_q0 && (srcR1_q0==5'd15);  //one-shot clears force-break bit in selected SCE break control register.  Lower 16 bits of x28 specifies to which SCE the action applies, which can be all 16.
assign XFRCRST_q0 = XORimm_0_q0 && (srcR1_q0==5'd16);  //one-shot sets force-reset bit in selected SCE break control register.  Lower 16 bits of x28 specifies to which SCE the action applies, which can be all 16.
assign XCLRRST_q0 = XORimm_0_q0 && (srcR1_q0==5'd17);  //one-shot clears force-reset bit in selected SCE break control register.  Lower 16 bits of x28 specifies to which SCE the action applies, which can be all 16.
assign XSSTEP_q0  = XORimm_0_q0 && (srcR1_q0==5'd18);  //while in break mode due to swbreak or hardware break, SSTEP is a one-shot that causes the SCE(s) specified by x28 to execute one instruction and advance the PC.
assign XSTATUS_q0 = XORimm_0_q0 && (srcR1_q0==5'd19);  //one-shot loads x30 with status of SCE specified by 16-bit one-hot value in lower 16 bits of x28. 

                                     
                                              
assign MREQ_q0 = XLDU_q0 || XLWU_q0 || XLHU_q0 || XLBU_q0 || XSD_q0 || XSW_q0 || XSH_q0 || XSB_q0 || XPUSH_q0 || XPULL_q0 || XPUSHD_q0; //any one of these will trigger monitor request to SCE

always @(posedge CLK)
    if (RESET) begin
        XLQU_q1a     <= 0;   
        XLDU_q1a     <= 0;   
        XLWU_q1a     <= 0; 
        XLHU_q1a     <= 0; 
        XLBU_q1a     <= 0; 
        XSQ_q1a      <= 0; 
        XSD_q1a      <= 0; 
        XSW_q1a      <= 0; 
        XSH_q1a      <= 0; 
        XSB_q1a      <= 0; 
        XPUSH_q1a    <= 0; 
        XPULL_q1a    <= 0; 
        XPUSHD_q1a   <= 0;
        XFRCBRK_q1a  <= 0; 
        XCLRBRK_q1a  <= 0; 
        XFRCRST_q1a  <= 0; 
        XCLRRST_q1a  <= 0; 
        XSSTEP_q1a   <= 0; 
        XSTATUS_q1a  <= 0; 
        XORimm_0_q1a <= 0; 
    end
    else if (risc_V_ready) begin
        XLQU_q1a     <= XLDU_q0;       
        XLDU_q1a     <= XLDU_q0;       
        XLWU_q1a     <= XLWU_q0;     
        XLHU_q1a     <= XLHU_q0;     
        XLBU_q1a     <= XLBU_q0;     
        XSQ_q1a      <= XSD_q0;      
        XSD_q1a      <= XSD_q0;      
        XSW_q1a      <= XSW_q0;      
        XSH_q1a      <= XSH_q0;      
        XSB_q1a      <= XSB_q0;      
        XPUSH_q1a    <= XPUSH_q0;    
        XPULL_q1a    <= XPULL_q0;    
        XPUSHD_q1a   <= XPUSHD_q0; 
        XFRCBRK_q1a  <= XFRCBRK_q0;  
        XCLRBRK_q1a  <= XCLRBRK_q0;  
        XFRCRST_q1a  <= XFRCRST_q0;  
        XCLRRST_q1a  <= XCLRRST_q0;  
        XSSTEP_q1a   <= XSSTEP_q0;   
        XSTATUS_q1a  <= XSTATUS_q0; 
        XORimm_0_q1a <= XORimm_0_q0; 
    end

assign XLQU_q1     = risc_V_cancel ? 0 : XLDU_q1a; 
assign XLDU_q1     = risc_V_cancel ? 0 : XLDU_q1a; 
assign XLWU_q1     = risc_V_cancel ? 0 : XLWU_q1a;     
assign XLHU_q1     = risc_V_cancel ? 0 : XLHU_q1a;     
assign XLBU_q1     = risc_V_cancel ? 0 : XLBU_q1a;     
assign XSQ_q1      = risc_V_cancel ? 0 : XSD_q1a;      
assign XSD_q1      = risc_V_cancel ? 0 : XSD_q1a;      
assign XSW_q1      = risc_V_cancel ? 0 : XSW_q1a;      
assign XSH_q1      = risc_V_cancel ? 0 : XSH_q1a;      
assign XSB_q1      = risc_V_cancel ? 0 : XSB_q1a;      
assign XPUSH_q1    = risc_V_cancel ? 0 : XPUSH_q1a;    
assign XPULL_q1    = risc_V_cancel ? 0 : XPULL_q1a;    
assign XPUSHD_q1   = risc_V_cancel ? 0 : XPUSHD_q1a;
assign XFRCBRK_q1  = risc_V_cancel ? 0 : XFRCBRK_q1a;   
assign XCLRBRK_q1  = risc_V_cancel ? 0 : XCLRBRK_q1a;   
assign XFRCRST_q1  = risc_V_cancel ? 0 : XFRCRST_q1a;   
assign XCLRRST_q1  = risc_V_cancel ? 0 : XCLRRST_q1a;   
assign XSSTEP_q1   = risc_V_cancel ? 0 : XSSTEP_q1a;     
assign XSTATUS_q1  = risc_V_cancel ? 0 : XSTATUS_q1a;  
assign XORimm_0_q1 = risc_V_cancel ? 0 : XORimm_0_q1a;    

endmodule
