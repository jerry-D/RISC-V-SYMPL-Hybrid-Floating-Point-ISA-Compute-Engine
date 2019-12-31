/*
 * Copyright (c) 2018, Marcelo Samsoniuk
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * * Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 * * Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * 
 * * Neither the name of the copyright holder nor the names of its
 *   contributors may be used to endorse or promote products derived from
 *   this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 */

//`timescale 1ns / 1ps
`timescale 1ns / 100ps

// implemented opcodes:

`define LUI     7'b01101_11      // lui   rd,imm[31:12]
`define AUIPC   7'b00101_11      // auipc rd,imm[31:12]
`define JAL     7'b11011_11      // jal   rd,imm[xxxxx]
`define JALR    7'b11001_11      // jalr  rd,rs1,imm[11:0] 
`define BCC     7'b11000_11      // bcc   rs1,rs2,imm[12:1]
`define LCC     7'b00000_11      // lxx   rd,rs1,imm[11:0]
`define SCC     7'b01000_11      // sxx   rs1,rs2,imm[11:0]
`define MCC     7'b00100_11      // xxxi  rd,rs1,imm[11:0]
`define RCC     7'b01100_11      // xxx   rd,rs1,rs2 
`define MAC     7'b11111_11      // mac   rd,rs1,rs2

// not implemented opcodes:

`define FCC     7'b00011_11      // fencex
`define CCC     7'b11100_11      // exx, csrxx
`define __RESETPC__ 32'h00000200
`define __RESETSP__ 32'h00002000

module darkriscv_mod
(
    CLK,   // clock
    RES,   // reset
    HLT,   // halt
    
    IREQ,  // irq req

    IDATA, // instruction data bus
    IADDR, // instruction addr bus
    
    DATAI, // data bus (input)
    DATAO, // data bus (output)
    DADDR, // addr bus
    
    WR,    // write enable
    RD,     // read enable
    
//--------------------------------------|
// stuff added by JDH  12/16/2019       |
//--------------------------------------| 
    SIZE,           //                  |
    RISC_V_cancel,  //                  |
    x31,            //                  |
    x30,            //                  |
    x29,            //                  |
    x28,            //                  |
    x27,            //                  |
    XPULL_q2,       //                  |
    XPUSH_q1,       //                  |
    XPUSHD_q1,      //                  |
    monRWsize_q1,   //                  |
    monRWsize_q2,   //                  |
    SigA_q1,        //                  |
    SigD_q2,        //                  |
    SCErddata,      //                  |
    SCEstatus       //                  |
//--------------------------------------|    
    );

    input             CLK;   // clock
    input             RES;   // reset
    input             HLT;   // halt
    
    input             IREQ;  // irq req

    input      [31:0] IDATA; // instruction data bus
    output     [31:0] IADDR; // instruction addr bus
    
    input      [31:0] DATAI; // data bus (input)
    output     [31:0] DATAO; // data bus (output)
    output     [31:0] DADDR; // addr bus
    
    output            WR;    // write enable
    output            RD;    // read enable 
    
//--------------------------------------------------------------------------------|
// stuff added by Jerry D. Harthcock  12/16/2019                                  |
//--------------------------------------------------------------------------------| 
output [2:0] SIZE;       //transaction size specifier                             |
output RISC_V_cancel;    //                                                       |
output [31:0] x31;       //register x31                                           |
output [31:0] x30;       //register x30                                           |
output [31:0] x29;       //register x29                                           |
output [31:0] x28;       //register x28                                           |
output [31:0] x27;       //register x27                                           |
output XPULL_q2;         //                                                       |
output XPUSH_q1;         //                                                       |
output XPUSHD_q1;        //                                                       |
output monRWsize_q1;         //                                                   |
output monRWsize_q2;         //                                                   |
output SigA_q1;              //                                                   |
output SigD_q2;              //                                                   |
input [63:0] SCErddata;  //data that comes from SCE                               |
input [31:0] SCEstatus;  //{SCE_IRQ, Done, swbreakDet, Break, frcBreak, frcReset} |
                         //                                                       |
//--------------------------------------------------------------------------------|

    reg [31:0] XIDATA;

    reg XLUI, XAUIPC, XJAL, XJALR, XBCC, XLCC, XSCC, XMCC, XRCC, XMAC; //, XFCC, XCCC;

    reg [31:0] XSIMM;
    reg [31:0] XUIMM;
    reg XMODE = 0;     // 0 = user, 1 = exception
    reg [1:0] FLUSH = -1;  // flush instruction pipeline
    reg [31:0] NXPC2 [0:1];       // 32-bit program counter t+2
    reg [5:0] RESMODE = 0;

    reg [31:0] NXPC;        // 32-bit program counter t+1
    reg [31:0] PC;		    // 32-bit program counter t+0
    
    reg [31:0] REG1 [0:63];	// general-purpose 32x32-bit registers (s1)
    reg [31:0] REG2 [0:63]; // general-purpose 32x32-bit registers (s2)    

    // dummy 32-bit words w/ all-0s and all-1s: 

    wire [31:0] ALL0  = 0;
    wire [31:0] ALL1  = -1;

    wire [5:0] DPTR   = RES ? RESMODE : { XMODE, XIDATA[11: 7] }; // set SP_RESET when RES==1
    wire [5:0] S1PTR  = { XMODE, XIDATA[19:15] };
    wire [5:0] S2PTR  = { XMODE, XIDATA[24:20] };
    wire [6:0] OPCODE = FLUSH ? 0 : XIDATA[6:0];
    wire [2:0] FCT3   = XIDATA[14:12];
    wire [6:0] FCT7   = XIDATA[31:25];

    wire [31:0] SIMM  = XSIMM;
    wire [31:0] UIMM  = XUIMM;
    
    // main opcode decoder:
                                
    wire    LUI = FLUSH ? 0 : XLUI;   // OPCODE==7'b0110111;
    wire  AUIPC = FLUSH ? 0 : XAUIPC; // OPCODE==7'b0010111;
    wire    JAL = FLUSH ? 0 : XJAL;   // OPCODE==7'b1101111;
    wire   JALR = FLUSH ? 0 : XJALR;  // OPCODE==7'b1100111;
    
    wire    BCC = FLUSH ? 0 : XBCC;   // OPCODE==7'b1100011; //FCT3
    wire    LCC = FLUSH ? 0 : XLCC;   // OPCODE==7'b0000011; //FCT3
    wire    SCC = FLUSH ? 0 : XSCC;   // OPCODE==7'b0100011; //FCT3
    wire    MCC = FLUSH ? 0 : XMCC;   // OPCODE==7'b0010011; //FCT3  immediates
    
    wire    RCC = FLUSH ? 0 : XRCC;   // OPCODE==7'b0110011; //FCT3  register to register

//---------- RISC_V / SYMPL Compute Engine gene-splice by JDH begins here ------------------------------------|
reg [31:0] IADDR_q1;      //                                                                                  |
reg [63:0] SCEin;         //                                                                                  |
reg XLOAD_q2;             //                                                                                  |
reg XLQU_q2;              //                                                                                  |
reg XLDU_q2;              //                                                                                  |
reg XLWU_q2;              //                                                                                  |
reg XLHU_q2;              //                                                                                  |
reg XLBU_q2;              //                                                                                  |
reg XPULL_q2;             //                                                                                  |
reg SigA_q1;              //                                                                                  |
reg SigD_q2;              //                                                                                  |
reg [2:0] monRWsize_q1;   //                                                                                  |
reg [2:0] monRWsize_q2;   //                                                                                  |
                          //                                                                                  |
wire RISC_V_cancel;       //                                                                                  |
wire XLQU_q1;             //                                                                                  |
wire XLDU_q1;             //                                                                                  |
wire XLWU_q1;             //                                                                                  |
wire XLHU_q1;             //                                                                                  |
wire XLBU_q1;             //                                                                                  |
wire XSQ_q1;              //                                                                                  |
wire XSD_q1;              //                                                                                  |
wire XSW_q1;              //                                                                                  |
wire XSH_q1;              //                                                                                  |
wire XSB_q1;              //                                                                                  |
wire XSTATUS_q1;          //                                                                                  |
wire XLOAD_q1;            //                                                                                  |
wire XPULL_q0;            //                                                                                  |
wire XPULL_q1;            //                                                                                  |
wire XPUSH_q0;            //                                                                                  |
wire XPUSH_q1;            //                                                                                  |
wire XPUSHD_q0;           //                                                                                  |
wire XPUSHD_q1;           //                                                                                  |
wire [2:0] srcAmntShft;   //                                                                                  |
wire [2:0] destAmntShft;  //                                                                                  |
wire [11:0] REPEAT;       //                                                                                  |
wire repeatGTone;         //                                                                                  |
wire [7:0] srcAmnt;       //                                                                                  |
wire [7:0] destAmnt;      //                                                                                  |
wire disableSrcAmnt;      //                                                                                  |
wire disableDestAmnt;     //                                                                                  |
wire monRDreq;            //                                                                                  |
wire monWRreq;            //                                                                                  |
wire [2:0] SIZE;          //                                                                                  |
wire [5:0] R27Ptr;        // same as for x30 during XPUSHD except it is the address for Side-B of RISC-V RAM  |
wire [5:0] R28Ptr;        // register 28 specifies which SCE(s) is/are to respond                             |
wire [5:0] R29Ptr;        // register 29 holds address used by SCE for reads and                              |
                          // writes to/from SCE memory/register space                                         |
wire [5:0] R30Ptr;        // register 30 holds address used by RISC-V for reads and writes                    |
                          // to/from RISC-V space or lower 32 bits in 64-bit "register-pair" operations       |
wire [5:0] R31Ptr;        // lower 12 bits of register 31 holds repeat value, upper bits hold src/dest        |
                          // size and pointer increment amount (push/pull) or upper 32 bits in 64-bit         |
                          // register-pair ops                                                                |
                                                 //                                                           |
assign R27Ptr = RES ? RESMODE : {XMODE, 6'd27};  //                                                           |
assign R28Ptr = RES ? RESMODE : {XMODE, 6'd28};  //                                                           |
assign R29Ptr = RES ? RESMODE : {XMODE, 6'd29};  //                                                           |
assign R30Ptr = RES ? RESMODE : {XMODE, 6'd30};  //                                                           |
assign R31Ptr = RES ? RESMODE : {XMODE, 6'd31};  //                                                           |
                                                                            //                                |
assign disableSrcAmnt = XPULL_q1 ? REG1[R31Ptr][19] : REG1[R31Ptr][27];     //                                |
assign disableDestAmnt = (XPUSH_q1||XPUSHD_q1) ? REG1[R31Ptr][19] : REG1[R31Ptr][27];    //                   |
assign srcAmntShft = XPULL_q1 ? REG1[R31Ptr][18:16] : REG1[R31Ptr][26:24];  //                                |
assign destAmntShft = (XPUSH_q1||XPUSHD_q1) ? REG1[R31Ptr][18:16] : REG1[R31Ptr][26:24]; //                   |
assign srcAmnt = disableSrcAmnt ? 0 : (1 << srcAmntShft);      //                                             |
assign destAmnt = disableDestAmnt ? 0 : (1 << destAmntShft);   //                                             |
assign REPEAT = REG1[R31Ptr][11:0];                            //                                             |
assign repeatGTone = (REPEAT>1) && (XPUSH_q0||XPULL_q0||XPUSHD_q0);       //                                  |
assign XLOAD_q1 = XLQU_q1 || XLDU_q1 || XLWU_q1 || XLHU_q1 || XLBU_q1;    //                                  |
assign RISC_V_cancel = |FLUSH;                                 //                                             |
assign x31 = REG1[R31Ptr];                                     //                                             |
assign x30 = REG1[R30Ptr];                                     //                                             |
assign x29 = REG1[R29Ptr];                                     //                                             |
assign x28 = REG1[R28Ptr];                                     //                                             |
assign x27 = REG1[R28Ptr];                                     //                                             |
assign SIZE = (XPULL_q1||XPUSH_q1||XPUSHD_q1) ? REG1[R31Ptr][22:20] :     //                                  |
               (XLQU_q1||XSQ_q1)   ? 3'b100 :                  //                                             |
               (XLDU_q1||XSD_q1)   ? 3'b011 :                  //                                             |
               (FCT3==0||FCT3==4)  ? 3'b000 :                  //                                             |
               ((FCT3==1||FCT3==5) ? 3'b001 : 3'b010);         //                                             |
                                                               //                                             |
assign monRDreq = XLQU_q1 || XLDU_q1 || XLWU_q1 || XLHU_q1 || XLBU_q1 || XPULL_q1;         //                 |
assign monWRreq = XSQ_q1 || XSD_q1 || XSW_q1 || XSH_q1 || XSB_q1 || XPUSH_q1 ||XPUSHD_q1;  //                 |
                                                               //                                             |
RISC_V_FUSED_INSTR FUSED_INSTR(                                //                                             |
    .CLK           (CLK          ),                            //                                             |
    .RESET         (RES          ),                            //                                             |
    .risc_V_ready  (~HLT         ),                            //                                             |
    .risc_V_instr  (IDATA        ),                            //                                             |
    .risc_V_cancel (RISC_V_cancel),                            //                                             |
    .SCE_sel       (|x28[15:0]   ),                            //                                             |
    .XLQU_q1       (XLQU_q1      ),                            //                                             |
    .XLDU_q1       (XLDU_q1      ),                            //                                             |
    .XLWU_q1       (XLWU_q1      ),                            //                                             |
    .XLHU_q1       (XLHU_q1      ),                            //                                             |
    .XLBU_q1       (XLBU_q1      ),                            //                                             |
    .XSQ_q1        (XSQ_q1       ),                            //                                             |
    .XSD_q1        (XSD_q1       ),                            //                                             |
    .XSW_q1        (XSW_q1       ),                            //                                             |
    .XSH_q1        (XSH_q1       ),                            //                                             |
    .XSB_q1        (XSB_q1       ),                            //                                             |
    .XPUSH_q1      (XPUSH_q1     ),                            //                                             |
    .XPULL_q1      (XPULL_q1     ),                            //                                             |
    .XPUSH_q0      (XPUSH_q0     ),                            //                                             |
    .XPULL_q0      (XPULL_q0     ),                            //                                             |
    .XPUSHD_q1     (XPUSHD_q1    ),                            //                                             |
    .XPUSHD_q0     (XPUSHD_q0    ),                            //                                             |
    .XFRCBRK_q1    (             ),                            //                                             |
    .XCLRBRK_q1    (             ),                            //                                             |
    .XFRCRST_q1    (             ),                            //                                             |
    .XCLRRST_q1    (             ),                            //                                             |
    .XSSTEP_q1     (             ),                            //                                             |
    .XSTATUS_q1    (XSTATUS_q1   ),                            //                                             |
    .MREQ_q0       (             )                             //                                             |
    );                                                         //                                             |
                                                               //                                             |
always @(posedge CLK) begin                                    //                                             |
    XLOAD_q2 <= XLOAD_q1;                                      //                                             |
    XLQU_q2  <= XLQU_q1;                                       //                                             |
    XLDU_q2  <= XLDU_q1;                                       //                                             |
    XLWU_q2  <= XLWU_q1;                                       //                                             |
    XLHU_q2  <= XLHU_q1;                                       //                                             |
    XLBU_q2  <= XLBU_q1;                                       //                                             |
    XPULL_q2 <= XPULL_q1;                                      //                                             |
    SigD_q2  <= SigA_q1;                                       //                                             |
    monRWsize_q2 <= monRWsize_q1;                              //                                             |
end                                                            //                                             |
                                                               //                                             |
always @(*)                                                    //                                             |
    if (XLQU_q2) SCEin = SCErddata;                                     //   for RV64I-only                   |
    else if (XLDU_q2) SCEin = SCErddata;                                //                                    |
    else if (XLWU_q2) SCEin = {REG1[R31Ptr], SCErddata[31:0]};          //                                    |
    else if (XLHU_q2) SCEin = {REG1[R31Ptr], 16'b0, SCErddata[15:0]};   //                                    |
    else if (XLBU_q2) SCEin = {REG1[R31Ptr], 24'b0, SCErddata[7:0]};    //                                    |
    else  SCEin = SCEstatus[31:0];                                      //                                    |
                                                                        //                                    |
always @(*)                                                                       //                          |
    if (XLDU_q1||XSD_q1) {SigA_q1, monRWsize_q1} = 4'b0011;                       //                          |
    else if (XLWU_q1||XSW_q1) {SigA_q1, monRWsize_q1} = 4'b0010;                  //                          |
    else if (XLHU_q1||XSH_q1) {SigA_q1, monRWsize_q1} = 4'b0001;                  //                          |
    else if (XLBU_q1||XSB_q1) {SigA_q1, monRWsize_q1} = 4'b0000;                  //                          |
    else if (XPUSH_q1||XPULL_q1||XPUSHD_q1) {SigA_q1, monRWsize_q1} = x31[15:12]; //                          |
    else  {SigA_q1, monRWsize_q1} = 4'b0100;                                      //                          |
                                                                                  //                          |
//------------------------------------------------------------------------------------------------------------|
                                                                                                              
    // pre-decode: IDATA is break apart as described in the RV32I specification

    always@(posedge CLK)
    begin        
        if(!HLT)
        begin
            XIDATA <= /*RES ? { ALL0[31:12], 5'd2, ALL0[6:0] } : HLT ? XIDATA : */IDATA;
            
            XLUI   <= /*RES ? 0 : HLT ? XLUI   : */IDATA[6:0]==`LUI;
            XAUIPC <= /*RES ? 0 : HLT ? XAUIPC : */IDATA[6:0]==`AUIPC;
            XJAL   <= /*RES ? 0 : HLT ? XJAL   : */IDATA[6:0]==`JAL;
            XJALR  <= /*RES ? 0 : HLT ? XJALR  : */IDATA[6:0]==`JALR;        

            XBCC   <= /*RES ? 0 : HLT ? XBCC   : */IDATA[6:0]==`BCC;
            XLCC   <= /*RES ? 0 : HLT ? XLCC   : */IDATA[6:0]==`LCC;
            XSCC   <= /*RES ? 0 : HLT ? XSCC   : */IDATA[6:0]==`SCC;
            XMCC   <= /*RES ? 0 : HLT ? XMCC   : */IDATA[6:0]==`MCC;

            XRCC   <= /*RES ? 0 : HLT ? XRCC   : */IDATA[6:0]==`RCC;
            XMAC   <= /*RES ? 0 : HLT ? XRCC   : */IDATA[6:0]==`MAC;
            //XFCC   <= RES ? 0 : HLT ? XFCC   : IDATA[6:0]==`FCC;
            //XCCC   <= RES ? 0 : HLT ? XCCC   : IDATA[6:0]==`CCC;

            // signal extended immediate, according to the instruction type:

            XSIMM  <= /*RES ? 0 : HLT ? SIMM :*/
                     IDATA[6:0]==`SCC ? { IDATA[31] ? ALL1[31:12]:ALL0[31:12], IDATA[31:25],IDATA[11:7] } : // s-type
                     IDATA[6:0]==`BCC ? { IDATA[31] ? ALL1[31:13]:ALL0[31:13], IDATA[31],IDATA[7],IDATA[30:25],IDATA[11:8],ALL0[0] } : // b-type
                     IDATA[6:0]==`JAL ? { IDATA[31] ? ALL1[31:21]:ALL0[31:21], IDATA[31], IDATA[19:12], IDATA[20], IDATA[30:21], ALL0[0] } : // j-type
                     IDATA[6:0]==`LUI||
                     IDATA[6:0]==`AUIPC ? { IDATA[31:12], ALL0[11:0] } : // u-type
                                          { IDATA[31] ? ALL1[31:12]:ALL0[31:12], IDATA[31:20] }; // i-type
            // non-signal extended immediate, according to the instruction type:

            XUIMM  <= /*RES ? 0: HLT ? UIMM :*/
                     IDATA[6:0]==`SCC ? { ALL0[31:12], IDATA[31:25],IDATA[11:7] } : // s-type
                     IDATA[6:0]==`BCC ? { ALL0[31:13], IDATA[31],IDATA[7],IDATA[30:25],IDATA[11:8],ALL0[0] } : // b-type
                     IDATA[6:0]==`JAL ? { ALL0[31:21], IDATA[31], IDATA[19:12], IDATA[20], IDATA[30:21], ALL0[0] } : // j-type
                     IDATA[6:0]==`LUI||
                     IDATA[6:0]==`AUIPC ? { IDATA[31:12], ALL0[11:0] } : // u-type
                                          { ALL0[31:12], IDATA[31:20] }; // i-type
        end
    end

    // source-1 and source-1 register selection

    wire signed   [31:0] S1REG = REG1[S1PTR];
    wire signed   [31:0] S2REG = REG2[S2PTR];
    
    wire          [31:0] U1REG = REG1[S1PTR];
    wire          [31:0] U2REG = REG2[S2PTR];
    
    // L-group of instructions (OPCODE==7'b0000011)    load

    wire [31:0] LDATA = FCT3==0||FCT3==4 ? ( DADDR[1:0]==3 ? { FCT3==0&&DATAI[31] ? ALL1[31: 8]:ALL0[31: 8] , DATAI[31:24] } :
                                             DADDR[1:0]==2 ? { FCT3==0&&DATAI[23] ? ALL1[31: 8]:ALL0[31: 8] , DATAI[23:16] } :
                                             DADDR[1:0]==1 ? { FCT3==0&&DATAI[15] ? ALL1[31: 8]:ALL0[31: 8] , DATAI[15: 8] } :
                                                             { FCT3==0&&DATAI[ 7] ? ALL1[31: 8]:ALL0[31: 8] , DATAI[ 7: 0] } ):
                        FCT3==1||FCT3==5 ? ( DADDR[1]==1   ? { FCT3==1&&DATAI[31] ? ALL1[31:16]:ALL0[31:16] , DATAI[31:16] } :
                                                             { FCT3==1&&DATAI[15] ? ALL1[31:16]:ALL0[31:16] , DATAI[15: 0] } ) :
                                             DATAI;

    // S-group of instructions (OPCODE==7'b0100011)    store

    wire [31:0] SDATA = FCT3==0 ? ( DADDR[1:0]==3 ? { U2REG[ 7: 0], ALL0 [23:0] } : 
                                    DADDR[1:0]==2 ? { ALL0 [31:24], U2REG[ 7:0], ALL0[15:0] } : 
                                    DADDR[1:0]==1 ? { ALL0 [31:16], U2REG[ 7:0], ALL0[7:0] } :
                                                    { ALL0 [31: 8], U2REG[ 7:0] } ) :
                        FCT3==1 ? ( DADDR[1]==1   ? { U2REG[15: 0], ALL0 [15:0] } :
                                                    { ALL0 [31:16], U2REG[15:0] } ) :
                                    U2REG;

    // C-group not implemented yet!
    
    wire [31:0] CDATA = 0;	// status register istructions not implemented yet

    // RM-group of instructions (OPCODEs==7'b0010011/7'b0110011), merged! src=immediate(M)/register(R)

    wire signed [31:0] S2REGX = XMCC ? SIMM : S2REG;
    wire        [31:0] U2REGX = XMCC ? UIMM : U2REG;

    wire [31:0] RMDATA = FCT3==7 ? U1REG&S2REGX :
                         FCT3==6 ? U1REG|S2REGX :
                         FCT3==4 ? U1REG^S2REGX :
                         FCT3==3 ? U1REG<U2REGX?1:0 : // unsigned
                         FCT3==2 ? S1REG<S2REGX?1:0 : // signed
                         FCT3==0 ? (XRCC&&FCT7[5] ? U1REG-U2REGX : U1REG+S2REGX) :
                         FCT3==1 ? U1REG<<U2REGX[4:0] :                         
                         //FCT3==5 ? 
                         FCT7[5] ? U1REG>>>U2REGX[4:0] : U1REG>>U2REGX[4:0]; // (FCT7[5] ? U1REG>>>U2REG[4:0] : U1REG>>U2REG[4:0])


    // J/B-group of instructions (OPCODE==7'b1100011)
    
    wire BMUX       = BCC==1 && (
                          FCT3==4 ? S1REG< S2REG : // blt
                          FCT3==5 ? S1REG>=S2REG : // bge
                          FCT3==6 ? U1REG< U2REG : // bltu
                          FCT3==7 ? U1REG>=U2REG : // bgeu
                          FCT3==0 ? U1REG==U2REG : // beq
                          FCT3==1 ? U1REG!=U2REG : // bne
                                    0);

    wire        JREQ = (JAL||JALR||BMUX);
    wire [31:0] JVAL = SIMM + (JALR ? U1REG : PC);


    always@(posedge CLK)
    begin
        RESMODE <= RESMODE +1;

	    FLUSH <= RES ? 2 : HLT ? FLUSH :        // reset and halt                              
	                       FLUSH ? FLUSH-1 :                           
	                       (JAL||JALR||BMUX) ? 2 : 0;  // flush the pipeline!
/*                           
        REG1[DPTR] <=   RES ? (RESMODE[4:0]==2 ? `__RESETSP__ : 0)  :        // reset sp
                       HLT ? REG1[DPTR] :        // halt
                     !DPTR ? 0 :                // x0 = 0, always!
                     AUIPC ? PC+SIMM :
                      JAL||
                      JALR ? NXPC :
                       LUI ? SIMM :
                       LCC ? LDATA :
                  MCC||RCC ? RMDATA:
                       //MCC ? MDATA :
                       //RCC ? RDATA : 
                       //CCC ? CDATA : 
                             REG1[DPTR];
                             
        REG2[DPTR] <=   RES ? (RESMODE[4:0]==2 ? `__RESETSP__ : 0) :        // reset sp
                       HLT ? REG2[DPTR] :        // halt
                     !DPTR ? 0 :                // x0 = 0, always!
                     AUIPC ? PC+SIMM :
                      JAL||
                      JALR ? NXPC :
                       LUI ? SIMM :
                       LCC ? LDATA :
                  MCC||RCC ? RMDATA:
                       //MCC ? MDATA :
                       //RCC ? RDATA : 
                       //CCC ? CDATA : 
                             REG2[DPTR];
*/
//---re-coding of above original code plus some new genetic material added by JDH for RISC-V-SCE gene splice ---------|
if (RES)            REG1[DPTR] <= (RESMODE[4:0]==2 ? `__RESETSP__ : 0);                                               //                                          
else if (HLT)       REG1[DPTR] <= REG1[DPTR];                                                                         //
else if (!DPTR)     REG1[DPTR] <= 0;                                                                                  //
else if (AUIPC)     REG1[DPTR] <= PC+SIMM;                                                                            //
else if (JAL||JALR) REG1[DPTR] <= NXPC;                                                                               //
else if (LUI)       REG1[DPTR] <= SIMM;                                                                               //
else if (LCC)       REG1[DPTR] <= LDATA;                                                                              //
else if (XLOAD_q2||XSTATUS_q1) {REG1[R31Ptr], REG1[R30Ptr]} <= SCEin;                                                 //                                          
else if (XPUSH_q1||XPUSHD_q1) begin                                                                                   //
                          REG1[R29Ptr] <= REG1[R29Ptr] + destAmnt;                                                    //
                          REG1[R30Ptr] <= REG1[R30Ptr] + srcAmnt;                                                     //
                          REG1[R27Ptr] <= XPUSHD_q1 ? (REG1[R27Ptr] + srcAmnt) : REG1[R27Ptr];                        //
                          REG1[R31Ptr][11:0] <= |REG1[R31Ptr][11:0] ? REG1[R31Ptr][11:0] - 1'b1 : REG1[R31Ptr][11:0]; //decrement REPEAT counter if not already zero 
                       end                                                                                            //
else if (XPULL_q1) begin                                                                                              //
                          REG1[R29Ptr] <= REG1[R29Ptr] + srcAmnt;                                                     //
                          REG1[R30Ptr] <= REG1[R30Ptr] + destAmnt;                                                    //
                          REG1[R31Ptr][11:0] <= |REG1[R31Ptr][11:0] ? REG1[R31Ptr][11:0] - 1'b1 : REG1[R31Ptr][11:0]; //decrement REPEAT counter if not already zero 
                       end                                                                                            //
else if (MCC||RCC)  REG1[DPTR] <= RMDATA;                                                                             //
else                REG1[DPTR] <= REG1[DPTR];                                                                         //
                                                                                                                      //
if (RES)            REG2[DPTR] <= (RESMODE[4:0]==2 ? `__RESETSP__ : 0);                                               //
else if (HLT)       REG2[DPTR] <= REG2[DPTR];                                                                         //
else if (!DPTR)     REG2[DPTR] <= 0;                                                                                  //
else if (AUIPC)     REG2[DPTR] <= PC+SIMM;                                                                            //
else if (JAL||JALR) REG2[DPTR] <= NXPC;                                                                               //
else if (LUI)       REG2[DPTR] <= SIMM;                                                                               //
else if (LCC)       REG2[DPTR] <= LDATA;                                                                              //
else if (XLOAD_q2||XSTATUS_q1) {REG2[R31Ptr], REG2[R30Ptr]} <= SCEin;                                                 //
else if (XPUSH_q1||XPUSHD_q1) begin                                                                                   //
                          REG2[R29Ptr] <= REG2[R29Ptr] + destAmnt;                                                    //
                          REG2[R30Ptr] <= REG2[R30Ptr] + srcAmnt;                                                     //
                          REG2[R27Ptr] <= XPUSHD_q1 ? (REG2[R27Ptr] + srcAmnt) : REG2[R27Ptr];                        //
                          REG2[R31Ptr][11:0] <= |REG2[R31Ptr][11:0] ? REG2[R31Ptr][11:0] - 1'b1 : REG2[R31Ptr][11:0]; //decrement REPEAT counter if not already zero 
                       end                                                                                            //
else if (XPULL_q1) begin                                                                                              //
                          REG2[R29Ptr] <= REG2[R29Ptr] + srcAmnt;                                                     //
                          REG2[R30Ptr] <= REG2[R30Ptr] + destAmnt;                                                    //
                          REG2[R31Ptr][11:0] <= |REG2[R31Ptr][11:0] ? REG2[R31Ptr][11:0] - 1'b1 : REG2[R31Ptr][11:0]; //decrement REPEAT counter if not already zero 
                       end                                                                                            //
else if (MCC||RCC)  REG2[DPTR] <= RMDATA;                                                                             //
else                REG2[DPTR] <= REG2[DPTR];                                                                         //
//--------------------------------------------------------------------------------------------------------------------|

//if (repeatNotZero) begin
if (repeatGTone) begin
   end
   else begin
        NXPC <= /*RES ? `__RESETPC__ :*/ HLT ? NXPC : NXPC2[XMODE];

        NXPC2[RES ? RESMODE[0] : XMODE] <=  RES ? `__RESETPC__ : HLT ? NXPC2[XMODE] :   // reset and halt
                                      JREQ ? JVAL :                            // jmp/bra
	                                         NXPC2[XMODE]+4;                   // normal flow

        XMODE <= RES ? 0 : HLT ? XMODE :        // reset and halt
	             XMODE==0&& IREQ&&(JAL||JALR||BMUX) ? 1 :         // wait pipeflush to switch to irq
                 XMODE==1&&!IREQ&&(JAL||JALR||BMUX) ? 0 : XMODE;  // wait pipeflush to return from irq

        PC   <= /*RES ? `__RESETPC__ :*/ HLT ? PC : NXPC; // current program counter
//----  added by JDH ---------|        
        IADDR_q1 <= IADDR; // | to support REPEAT
//----------------------------|     
   end
 end  

    // IO and memory interface

    assign DATAO = SDATA; // SCC ? SDATA : 0;
    assign DADDR = U1REG + SIMM; // (SCC||LCC) ? U1REG + SIMM : 0;

    assign RD = LCC;                                                                                     
    assign WR = SCC;
    
//	assign IADDR = NXPC2[XMODE];
//-----------  modified by JDH to support REPEAT ---------------|
	assign IADDR = repeatGTone ? IADDR_q1 : NXPC2[XMODE];    // |
//--------------------------------------------------------------|                                                                                     
endmodule
