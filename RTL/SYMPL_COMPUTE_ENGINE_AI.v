// SYMPL_COMPUTE_ENGINE_AI.v
//
// Author:  Jerry D. Harthcock
// Version:  1.21  November 30, 2019
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


module SYMPL_COMPUTE_ENGINE_AI (
   CLK,
   RESET_IN,

//   ready_q1,  
   done,      
   IRQ,    
  
   RISC_V_ready, 
   RISC_V_instr,
   RISC_V_cancel, //cancel currently fetched and registered RISC_V instruction  
   x31,             // RISC-V x31 register input to SCE
   x30,             // RISC-V x30 register input to SCE
   x29,             // RISC-V x29 register input to SCE
   RISC_V_RAMrddataA,  //data read from RISC-V data RAM (A-side) during XPUSH or XPUSHD instruction execution
   RISC_V_RAMrddataB,  //data read from RISC-V data RAM (B-side)during XPUSHD instruction execution
   SCE_sel,         // compute engine select
   SCErddata, // read data from SCE
   SCEstatus // status bits from SCE
   );
      
input CLK;
input RESET_IN;

//input  ready_q1;  
output done;      
input  IRQ;       

input RISC_V_ready;
input [31:0] RISC_V_instr;
input RISC_V_cancel;
input [31:0] x31;       
input [31:0] x30;       
input [31:0] x29;       
input  SCE_sel;  
input [63:0] RISC_V_RAMrddataA;     
input [63:0] RISC_V_RAMrddataB;     
output [63:0] SCErddata; 
output [7:0] SCEstatus;

parameter     BRAL_ =  15'h7FF6;   // branch relative long
parameter     JMPA_ =  15'h7FF5;   // jump absolute long
parameter     BTBS_ =  15'h7FF4;   // bit test and branch if set
parameter     BTBC_ =  15'h7FF3;   // bit test and branch if clear

parameter               BRAL_ADDRS = 32'h00007FF6;   // branch relative long
parameter               JMPA_ADDRS = 32'h00007FF5;   // jump absolute long
parameter               BTBS_ADDRS = 32'h00007FF4;   // bit test and branch if set
parameter               BTBC_ADDRS = 32'h00007FF3;   // bit test and branch if clear

parameter             SP_TOS_ADDRS = 32'h00007FFF;
parameter                 SP_ADDRS = 32'h00007FFE;
parameter                AR6_ADDRS = 32'h00007FFD;
parameter                AR5_ADDRS = 32'h00007FFC;
parameter                AR4_ADDRS = 32'h00007FFB;
parameter                AR3_ADDRS = 32'h00007FFA;
parameter                AR2_ADDRS = 32'h00007FF9;
parameter                AR1_ADDRS = 32'h00007FF8;
parameter                AR0_ADDRS = 32'h00007FF7;
parameter                 PC_ADDRS = 32'h00007FF5;
parameter            PC_COPY_ADDRS = 32'h00007FF2;
parameter                 ST_ADDRS = 32'h00007FF1;
parameter               PRNG_ADDRS = 32'h00007FF0;
parameter             REPEAT_ADDRS = 32'h00007FEF;
parameter             LPCNT1_ADDRS = 32'h00007FEE;
parameter             LPCNT0_ADDRS = 32'h00007FED;
parameter              TIMER_ADDRS = 32'h00007FEC;
parameter                MON_ADDRS = 32'h00007FEB;

parameter         SPARE_VEC1_ADDRS = 15'h7FE8;
parameter         SPARE_VEC0_ADDRS = 15'h7FE7;
parameter         NMI_VECTOR_ADDRS = 15'h7FE6;
parameter         IRQ_VECTOR_ADDRS = 15'h7FE5;
parameter     invalid_VECTOR_ADDRS = 15'h7FE4;
parameter      divby0_VECTOR_ADDRS = 15'h7FE3;
parameter    overflow_VECTOR_ADDRS = 15'h7FE2;
parameter   underflow_VECTOR_ADDRS = 15'h7FE1;
parameter     inexact_VECTOR_ADDRS = 15'h7FE0;

parameter              CAPT3_ADDRS = 32'h00007FDD;
parameter              CAPT2_ADDRS = 32'h00007FDC;
parameter              CAPT1_ADDRS = 32'h00007FDB;
parameter              CAPT0_ADDRS = 32'h00007FDA;

parameter           SAVFLAGS_ADDRS = 32'h00007FD9; //store status register here to save flags, read here to get them
parameter             RNDDIR_ADDRS = 32'h00007FD8;
parameter           SAVMODES_ADDRS = 32'h00007FD7; //store status register here to save modes, read here to get them            
parameter              CLASS_ADDRS = 32'h00007FD6;
parameter              RADIX_ADDRS = 32'h00007FD5;
parameter             is2008_ADDRS = 15'h7FD0;
parameter        INTEGER_CMP_ADDRS = 15'h7FCF;
parameter            actMode_ADDRS = 15'h7FCD;  // neural network activation Mode
parameter     FLOAT_ADDRS = 32'b0000_0000_0000_0000_0111_10xx_xxxx_xxxx;  //floating-point operator block 78xx--7Bxx
parameter    INTEGR_ADDRS = 32'b0000_0000_0000_0000_0111_1110_xxxx_xxxx;  // integer and logic operator block  7Exx
parameter  PRIV_RAM_ADDRS = 32'b0000_0000_0000_0000_0xxx_xxxx_xxxx_xxxx;    //first 32k bytes (since data memory is byte-addressable and smallest RAM for this in Kintex 7 is 2k x 64 bits using two blocks next to each other

parameter             is1985_ADDRS = 32'h00000000;  //read this to get 0 (false)
                            
reg [`PCWIDTH-1:0] pc_q1;
reg [`PCWIDTH-1:0] pc_q2;

reg [63:0] wrsrcAdataSext;
reg [63:0] wrsrcBdataSext;
reg [63:0] wrsrcAdata;
reg [63:0] wrsrcBdata;

reg fp_ready_q2;
reg fp_sel_q2;

reg [3:0]  STATE;
                                                                                           
reg [1:0]  RM_q1; 
reg [1:0]  NN_Mode_q1;
reg [1:0]  Dam_q1; 
reg        SigD_q1;
reg [2:0]  Size_Dest_q1;  
reg        Ind_Dest_q1;
reg        Imod_Dest_q1; 
reg [14:0] OPdest_q1;
reg        SigA_q1;
reg [2:0]  Size_SrcA_q1;  
reg        Ind_SrcA_q1; 
reg [14:0] OPsrcA_q1; 
reg        SigB_q1;
reg  [2:0] Size_SrcB_q1;  
reg        Ind_SrcB_q1; 
reg [14:0] OPsrcB_q1; 
reg [31:0] OPsrc32_q1; 

reg [1:0]   RM_q2; 
reg [1:0]  NN_Mode_q2;
reg [1:0]  Dam_q2; 
reg        SigD_q2;
reg [2:0]  Size_Dest_q2;  
reg        Ind_Dest_q2;
reg        Imod_Dest_q2; 
reg [14:0] OPdest_q2;
//reg        Sext_SrcA_q2; 
reg        SigA_q2;
reg [2:0]  Size_SrcA_q2;  
reg        Ind_SrcA_q2; 
reg [14:0] OPsrcA_q2; 
reg        SigB_q2;
reg  [2:0] Size_SrcB_q2;  
reg        Ind_SrcB_q2; 
reg [14:0] OPsrcB_q2; 
reg [31:0] OPsrc32_q2;

reg [31:0] SrcA_addrs_q1;
reg [31:0] SrcB_addrs_q1;
reg [31:0] SrcA_addrs_q2;
reg [31:0] SrcB_addrs_q2;

reg [15:0] immediate16_q1;

reg RESET;
wire RESET_OUT;

reg C_q2;
reg V_q2;
reg N_q2;
reg Z_q2;
reg write_collision_os;
reg write_collision_os_q1;

reg sig_stk_rden_q1; 
reg [4:0] pulled_signals_q2;
reg restore_q1;
reg restore_q2;

wire [63:0] SCErddata;

wire break_q0;
wire break_q1;
wire break_q2;

wire [`PCWIDTH-1:0] pre_PC;

wire  [1:0] RM_q0;

wire [1:0] Dam_q0;
wire Ind_SrcA_q0;
wire Ind_SrcB_q0;
wire Ind_Dest_q0;
wire Imod_SrcA_q0;
wire Imod_SrcB_q0;
wire Imod_Dest_q0;
wire [2:0] Size_SrcA_q0;
wire [2:0] Size_SrcB_q0;
wire [2:0] Size_Dest_q0;
wire        SigA_q0;
wire        SigB_q0; 
wire        SigD_q0; 
wire [31:0] OPsrc32_q0;
wire [14:0] OPsrcA_q0;
wire [14:0] OPsrcB_q0;
wire [14:0] OPdest_q0;

wire [15:0] immediate16_q0;

wire [5:0] sextA_sel;
wire [5:0] sextB_sel;

wire C_q1;
wire V_q1;
wire N_q1;
wire Z_q1;

wire fp_ready_q1;

reg fp_sel_q1;

wire monRDreq;

wire [63:0] Instruction_q0;
wire [63:0] Instruction_q0_del;
wire [63:0] priv_RAM_rddataA;
wire [63:0] priv_RAM_rddataB;
wire [63:0] glob_RAM_rddataA;
wire [63:0] glob_RAM_rddataB;

wire [4:0] exc_codeA;
wire [4:0] exc_codeB;

wire int_in_service;

wire [`PCWIDTH-1:0] vector;

wire rdcycl;
wire wrcycl;

wire [63:0] float_rddataA;
wire [63:0] float_rddataB;                                                                                                           

wire [67:0] rddataA_integer;             
wire [67:0] rddataB_integer; 
wire ready_integer_q1;

wire write_collision;

wire [63:0] rdSrcAdata;
wire [63:0] core_rdSrcAdata;
wire [63:0] rdSrcBdata;
wire [63:0] core_rdSrcBdata;
wire [31:0] Dest_addrs_q2;
wire [31:0] Dest_addrs_q0;
wire [31:0] coreDest_addrs_q2;
wire [31:0] SrcA_addrs_q0;
wire [31:0] coreSrcA_addrs_q0;
wire [31:0] SrcB_addrs_q0;
wire [63:0] mon_read_reg;    
wire [`PCWIDTH-1:0] PC;
wire C;
wire V;
wire N;
wire Z;
wire done;
wire IRQ_IE;
wire RPT_not_z;
wire rewind_PC;
wire ld_vector;
wire discont;
wire RM_Attribute_on;
wire [1:0] RM;
wire [1:0] NN_Mode_q0;
wire Away;

wire statusRWcollision;
wire write_disable;      //from PC block
wire writeAbort;         //from FP exception capture

wire [31:0] mon_read_addrs; 
wire [31:0] mon_write_addrs_q2;

wire ind_mon_read_q0; 
wire ind_mon_write_q2;

reg tableRead_q1;
wire tableRead_q0;
assign tableRead_q0 = SrcA_addrs_q0[31] || (Dam_q0[1:0]==2'b10);
wire tableWrite_q2;
assign tableWrite_q2 = wrcycl && Dest_addrs_q2[31];      
wire [63:0] tableReadData_q1;  

wire [1023:0] fat_RAM_rddataA;
wire [1023:0] fat_RAM_rddataB;

assign RM_q0[1:0] = RM_Attribute_on ? RM[1:0] : Instruction_q0_del[63:62];
assign NN_Mode_q0[1:0] = Instruction_q0_del[63:62];

reg [1023:0] fat_wrsrcAdataSext;    
reg [1023:0] fat_wrsrcBdataSext;
reg fat_rddataA_sel_q1;
reg fat_rddataB_sel_q1;
reg FuNNrdenA_q1;
reg FuNNrdenB_q1;

wire fat_wrdata_sel;
wire fat_rddataA_sel;
wire fat_rddataB_sel;
assign fat_wrdata_sel = wrcycl && (Dest_addrs_q2[31:15]=={16'b0, 1'b1});
assign fat_rddataA_sel = (SrcA_addrs_q0[31:15]=={16'b0, 1'b1}) || (SrcA_addrs_q0[31:16]==16'h0001);    
assign fat_rddataB_sel = (SrcB_addrs_q0[31:15]=={16'b0, 1'b1}) || (SrcB_addrs_q0[31:16]==16'h0001); 

wire [3:0] ACTM;
wire [1023:0] FuNNrddataA;
wire [1023:0] FuNNrddataB;
wire FuNNwren;
wire FuNNrdenA;
wire FuNNrdenB;
assign FuNNrdenA = SrcA_addrs_q0[31:9]==23'b0000_0000_0000_0000_0100_000;
assign FuNNrdenB = SrcB_addrs_q0[31:9]==23'b0000_0000_0000_0000_0100_000;
assign FuNNwren =  (Dest_addrs_q2[31:9]==23'b0000_0000_0000_0000_0100_000) && wrcycl;
wire [4:0] FuNN_except_A;
wire [4:0] FuNN_except_B;
wire FuNN_ready_q1;
wire PRNG_ready_q0;
reg PRNG_ready_q1;


wire toDecCharRddataA_sel;
wire toDecCharRddataB_sel;
reg toDecCharRddataA_sel_q1;
reg toDecCharRddataB_sel_q1;
wire [375:0] toDecCharRddataA;
wire [375:0] toDecCharRddataB;
wire [4:0] pulled_signals_q1;

wire [63:0] mon_writeData_q2;
wire monWRreq_q1;

assign SCErddata = rdSrcAdata;


assign toDecCharRddataA_sel = (~Dam_q0[1] && (SrcA_addrs_q0[31:12]==20'h00007) && (SrcA_addrs_q0[11:5]==7'b1010101));
assign toDecCharRddataB_sel = (~Dam_q0[0] && (SrcB_addrs_q0[31:12]==20'h00007) && (SrcB_addrs_q0[11:5]==7'b1010101));

assign rdSrcAdata = fat_rddataA_sel_q1 ? (sig_stk_rden_q1 ? {59'b0, pulled_signals_q1} : fat_RAM_rddataA[63:0]) : tableRead_q1 ? tableReadData_q1 : core_rdSrcAdata;

assign rdSrcBdata = fat_rddataB_sel_q1 ? fat_RAM_rddataB[63:0] : core_rdSrcBdata;
                                                               

assign Dest_addrs_q2 = ind_mon_write_q2 ? mon_write_addrs_q2 : coreDest_addrs_q2;
assign SrcA_addrs_q0 = ind_mon_read_q0 ? mon_read_addrs : coreSrcA_addrs_q0;

assign C_q1 = rddataA_integer[67];
assign V_q1 = rddataA_integer[66];
assign N_q1 = rddataA_integer[65];
assign Z_q1 = rddataA_integer[64];

assign sextA_sel = {Size_Dest_q2[2:0], Size_SrcA_q2[2:0]};       
assign sextB_sel = {Size_Dest_q2[2:0], Size_SrcB_q2[2:0]};

assign Dam_q0[1:0]       = Instruction_q0_del[61:60]; 
assign SigD_q0           = Instruction_q0_del[59];   
assign Size_Dest_q0[2:0] = Instruction_q0_del[58:56]; 
assign Ind_Dest_q0       = Instruction_q0_del[55]; 
assign Imod_Dest_q0      = Instruction_q0_del[54];   //borrows msb of destination operand
assign OPdest_q0[14:0]   = Instruction_q0_del[54:40]; 
assign SigA_q0           = Instruction_q0_del[39]; 
assign Size_SrcA_q0[2:0] = Instruction_q0_del[38:36]; 
assign Ind_SrcA_q0       = Instruction_q0_del[35]; 
assign Imod_SrcA_q0      = Instruction_q0_del[34];   //borrows msb of SrcA operand
assign OPsrcA_q0[14:0]   = Instruction_q0_del[34:20];
assign SigB_q0           = Instruction_q0_del[19]; 
assign Size_SrcB_q0[2:0] = Instruction_q0_del[18:16]; 
assign Ind_SrcB_q0       = Instruction_q0_del[15];   
assign Imod_SrcB_q0      = Instruction_q0_del[14];   //borrows msb of SrcB operand
assign OPsrcB_q0[14:0]   = Instruction_q0_del[14:0]; 
assign OPsrc32_q0[31:0]  = Instruction_q0_del[31:0]; 

assign immediate16_q0[15:0] = Instruction_q0_del[15:0];

wire fp_sel_q0;     
assign fp_sel_q0 = (~Dam_q0[1] && (SrcA_addrs_q0[31:12]==20'h00007) && (SrcA_addrs_q0[11:10]==2'b10)) || 
                   (~Dam_q0[1] && (SrcB_addrs_q0[31:12]==20'h00007) && (SrcB_addrs_q0[11:10]==2'b10));
                         

wire ready_q0;
wire fp_ready_q0;
wire FuNN_ready_q0;
assign fp_ready_q0 = 1'b1;
wire ready_integer_q0;
assign ready_integer_q0 = 1'b1;
wire dest_not_FP_or_Integer;
assign dest_not_FP_or_Integer = ~(Dest_addrs_q0[31:12]==20'h00007);

assign write_collision = ((SrcA_addrs_q1[31:0]==Dest_addrs_q2[31:0]) || (SrcB_addrs_q1[31:1]==Dest_addrs_q2[31:1]) || statusRWcollision) && ~write_collision_os && ~write_collision_os_q1 && ~break_q0 && ~break_q1 && wrcycl  && ~(Dam_q1[1:0]==2'b10) && ~SrcB_addrs_q1[31] && |Dest_addrs_q2[31:0];

//assign rewind_PC = (~fp_ready_q1 || ~ready_integer_q1 || write_collision || ~ready_q1 || ~FuNN_ready_q1 || ~PRNG_ready_q1);
assign rewind_PC = (~fp_ready_q1 || ~ready_integer_q1 || write_collision || ~FuNN_ready_q1 || ~PRNG_ready_q1);
assign ready_q0 = FuNN_ready_q0 && fp_ready_q0 && ready_integer_q0 && PRNG_ready_q0;    
assign rdcycl = 1'b1;
assign wrcycl = (STATE[2] && ~write_disable && ~writeAbort) || break_q2;

wire fat_push;
assign fat_push = fat_wrdata_sel && (OPdest_q2[2:0]==3'b111) && Ind_Dest_q2 && ~Imod_Dest_q2; 
wire [4:0] FP_Dx0_Inv_Ovf_Unf_Nxact;  
assign FP_Dx0_Inv_Ovf_Unf_Nxact = exc_codeA;
wire fat_pull;
assign fat_pull = fat_rddataA_sel && (OPsrcA_q0[2:0]==3'b111) && (Dam_q0[1:0]==2'b00) && Ind_SrcA_q0 && ~Imod_SrcA_q0;

wire _3portFatRAM_wrsel;
assign _3portFatRAM_wrsel = wrcycl && ~|Dest_addrs_q2[31:17] && Dest_addrs_q2[16];
wire  _3portFatRAM_rdselA;
assign _3portFatRAM_rdselA = ~|SrcA_addrs_q0[31:17] && SrcA_addrs_q0[16];
wire  _3portFatRAM_rdselB;
assign _3portFatRAM_rdselB = ~|SrcB_addrs_q0[31:17] && SrcB_addrs_q0[16];
wire [2:0] _3portWRsize;
assign _3portWRsize = Size_Dest_q2[2:0];
wire [2:0] _3portRDsizeA;
assign _3portRDsizeA = Size_SrcA_q0[2:0];
wire [2:0] _3portRDsizeB;
assign _3portRDsizeB = Size_SrcB_q0[2:0];
wire [15:0] _3portWraddrs;
assign _3portWraddrs = Dest_addrs_q2[15:0];
wire [15:0] _3portRdaddrsA;
assign _3portRdaddrsA = SrcA_addrs_q0[15:0];
wire [15:0] _3portRdaddrsB;
assign _3portRdaddrsB = SrcB_addrs_q0[15:0];
wire [1023:0] _3portWrdata;
assign _3portWrdata = fat_wrsrcAdataSext[1023:0];


reg _3portFatRAM_rdselA_q1;
reg _3portFatRAM_rdselB_q1;

wire [1023:0] fat_RAM_rddataA_LO;
wire [1023:0] fat_RAM_rddataB_LO;
wire [1023:0] fat_RAM_rddataA_HI;
wire [1023:0] fat_RAM_rddataB_HI;
                                    
                                    
assign fat_RAM_rddataA[1023:0] = FuNNrdenA_q1 ? FuNNrddataA : (_3portFatRAM_rdselA_q1 ? fat_RAM_rddataA_HI[1023:0] : fat_RAM_rddataA_LO[1023:0]);
assign fat_RAM_rddataB[1023:0] = FuNNrdenB_q1 ? FuNNrddataB : (_3portFatRAM_rdselB_q1 ? fat_RAM_rddataB_HI[1023:0] : fat_RAM_rddataB_LO[1023:0]);


wire [7:0] SCEstatus;
wire frc_brk;      
wire broke;        
wire skip_cmplt;      
wire swbreakDetect;
wire [63:0] mon_writeData_q1;
wire XPULL_q2;    
wire XPUSH_q1;    
wire XPUSH_q2;    
wire XPUSHD_q1;    
wire XPUSHD_q2;    
wire [2:0] monRWsize_q1;
wire [2:0] monRWsize_q2;

assign  SCEstatus = {1'b0, IRQ, done, skip_cmplt, swbreakDetect, broke, frc_brk, RESET_OUT};
SCE_breakpoints breakpoints(
    .CLK                (CLK                ),
    .RESET_IN           (RESET_IN           ),
    .RESET_OUT          (RESET_OUT          ),
    .Instruction_q0     (Instruction_q0     ),
    .Instruction_q0_del (Instruction_q0_del ),
                                            
    .break_q0           (break_q0           ),
    .break_q1           (break_q1           ),
    .break_q2           (break_q2           ),
    .ind_mon_read_q0    (ind_mon_read_q0    ),
    .ind_mon_write_q2   (ind_mon_write_q2   ),
    .monRDreq           (monRDreq           ),
    .mon_write_addrs_q2 (mon_write_addrs_q2 ),
    .mon_read_addrs     (mon_read_addrs     ),
    .mon_writeData_q1   (mon_writeData_q1   ),
    .monWRreq_q1        (monWRreq_q1        ),
    .XPULL_q2           (XPULL_q2           ),
    .XPUSH_q1           (XPUSH_q1           ),
    .XPUSH_q2           (XPUSH_q2           ),
    .XPUSHD_q1          (XPUSHD_q1          ),
    .XPUSHD_q2          (XPUSHD_q2          ),
    .monRWsize_q1       (monRWsize_q1       ),
    .monRWsize_q2       (monRWsize_q2       ),

    .frc_brk            (frc_brk            ),
    .broke              (broke              ),
    .skip_cmplt         (skip_cmplt         ),
    .swbreakDetect      (swbreakDetect      ),
    
    .RISC_V_ready       (RISC_V_ready       ),
    .RISC_V_instr       (RISC_V_instr       ),
    .RISC_V_cancel      (RISC_V_cancel      ), //cancel currently fetched and registered RISC_V instruction  
    
    .x31                (x31                ),
    .x30                (x30                ),
    .x29                (x29                ),
    .SCE_sel            (SCE_sel            )
    );                                      



//float operators are mapped to direct/indirect access range 0x000078xx to 0x00007Bxx
`ifdef SCE_HAS_FLOAT                       
    fpmath_DP fpmath( 
        .RESET        (RESET               ),
        .CLK          (CLK                 ),
        .wren         (wrcycl && (Dest_addrs_q2[31:12]==20'h00007) && (Dest_addrs_q2[11:10]==2'b10) ),  //float operator block select
        .wraddrs      (Dest_addrs_q2[10:0] ),
        .SigD_q2      (SigD_q2             ),
        .Size_Dest_q2 (Size_Dest_q2[1:0]   ),
        .SigA_q2      (SigA_q2             ),
        .Size_SrcA_q2 (Size_SrcA_q2[2:0]   ),                          
        .wrdataA      (wrsrcAdataSext[63:0]),
        .SigB_q2      (SigB_q2             ),
        .Size_SrcB_q2 (Size_SrcB_q2[2:0]   ),
        .wrdataB      (wrsrcBdataSext[63:0]),
        .rdenA        (~Dam_q0[1] && (SrcA_addrs_q0[31:12]==20'h00007) && (SrcA_addrs_q0[11:10]==2'b10)),    //direct or indirect read
        .rdaddrsA     (SrcA_addrs_q0[10:0] ),
        .rddataA      (float_rddataA[63:0] ),
        .rdenB        (~Dam_q0[0] && (SrcB_addrs_q0[31:12]==20'h00007) && (SrcB_addrs_q0[11:10]==2'b10)),
        .rdaddrsB     (SrcB_addrs_q0[10:0] ),
        .rddataB      (float_rddataB[63:0] ),
        .exc_codeA    (exc_codeA           ),
        .exc_codeB    (exc_codeB           ),
        .ready        (fp_ready_q1         ),
        .round_mode_q2(RM_q2               ),
        .Away         (Away                ),
        .fat_in_A     (fat_wrsrcAdataSext[375:0]),
        .fat_in_B     (fat_wrsrcBdataSext[375:0]),
        .fat_out_A    (toDecCharRddataA[375:0]),
        .fat_out_B    (toDecCharRddataB[375:0]),
        .restore_q2   (restore_q2          ),
        .pulled_signals_q2(pulled_signals_q2  )      //{divBy0, invalid, overflow, underflow, inexact}
        );
`else
    assign float_rddataA[63:0] = 64'b0;
    assign float_rddataB[63:0] = 64'b0;
    assign fp_ready_q1 = 1'b1;
    assign exc_codeA = 5'b00000;
    assign exc_codeB = 5'b00000;
    assign toDecCharRddataA[375:0] = 0;
    assign toDecCharRddataB[375:0] = 0;
`endif

always @(posedge CLK)
    if (RESET) FuNNrdenA_q1 <= 0;
    else FuNNrdenA_q1 <= FuNNrdenA;
    
always @(posedge CLK)
    if (RESET) FuNNrdenB_q1 <= 0;
    else FuNNrdenB_q1 <= FuNNrdenB;

    
`ifdef SCE_HAS_FuNN    
FuNN FuNN(
    .CLK(CLK),
    .RESET(RESET),
    .RM(2'b00),
    .ACT(NN_Mode_q2[1]),     // 1 = activate, 0 = bipass activation
    .ADT(NN_Mode_q2[0]),     // 1 = add total, 0 = add 0
    .actSel(ACTM),
    .SizeA_q0(Size_SrcA_q0[2:0]),
    .SizeB_q0(Size_SrcB_q0[2:0]),
    .SizeA_q2(Size_SrcA_q2[2:0]),
    .SizeB_q2(Size_SrcB_q2[2:0]),
    .SizeD_q2(Size_Dest_q2[2:0]),
    .SigA_q2(SigA_q2),
    .SigB_q2(SigB_q2),
    .SigD_q2(SigD_q2),
    .wren(FuNNwren),
    .wraddrs(Dest_addrs_q2[12:0]),
    .wrdataA(fat_wrsrcAdataSext[1023:0]),
    .wrdataB(fat_wrsrcBdataSext[1023:0]),
    .rdenA(FuNNrdenA),
    .rdaddrsA(SrcA_addrs_q0[12:0]),
    .rddataA(FuNNrddataA[1023:0]),
    .rdenB(FuNNrdenB),
    .rdaddrsB(SrcB_addrs_q0[12:0]),
    .rddataB(FuNNrddataB[1023:0]),
    .exceptA(FuNN_except_A),
    .exceptB(FuNN_except_B),
    .restore(restore_q2),
    .ready(FuNN_ready_q1),
    .ready_q0(FuNN_ready_q0)
    );
`else
assign FuNNrddataA = 0;
assign FuNNrddataB = 0;
assign FuNN_except_A = 0;
assign FuNN_except_B = 0;
assign FuNN_ready_q1 = 1;
assign FuNN_ready_q0 = 1;
`endif

SCE_core SCE_core(                                         
   .CLK            (CLK             ),                       
   .RESET          (RESET           ),                       
   .q1_sel         (STATE[1]        ),              
   .q2_sel         (STATE[2]        ),              
   .wrsrcAdata     (wrsrcAdata[63:0]),                       
   .wrsrcBdata     (wrsrcBdata[63:0]),                       
   .rdSrcAdata     (core_rdSrcAdata ),                       
   .rdSrcBdata     (core_rdSrcBdata ),                       
   .priv_RAM_rddataA (priv_RAM_rddataA[63:0]),                      
   .priv_RAM_rddataB (priv_RAM_rddataB[63:0]),                      
   .glob_RAM_rddataA (glob_RAM_rddataA[63:0]),                      
   .glob_RAM_rddataB (glob_RAM_rddataB[63:0]),                      
   .ld_vector      (ld_vector       ),
   .vector         (vector          ),                       
   .pre_PC         (pre_PC          ),                       
   .PC             (PC              ),                      
   .pc_q1          (pc_q1           ), 
   .pc_q2          (pc_q2           ), 
   .rewind_PC      (rewind_PC       ),                       
   .wrcycl         (wrcycl          ),                       
   .discont_out    (discont         ),                       
   .OPsrcA_q0      (OPsrcA_q0[14:0] ),
   .OPsrcA_q1      (OPsrcA_q1[14:0] ),
   .OPsrcA_q2      (OPsrcA_q2[14:0] ),                       
   .OPsrcB_q0      (OPsrcB_q0[14:0] ),                       
   .OPsrcB_q1      (OPsrcB_q1[14:0] ),                       
   .OPsrcB_q2      (OPsrcB_q2[14:0] ),                       
   .OPdest_q0      (OPdest_q0[14:0] ),                       
   .OPdest_q1      (OPdest_q1[14:0] ),                       
   .OPdest_q2      (OPdest_q2[14:0] ), 
   .immediate16_q0 (immediate16_q0  ),                      
   .RPT_not_z      (RPT_not_z       ),                       
   .Dam_q0         (Dam_q0[1:0]     ),                       
   .Dam_q1         (Dam_q1[1:0]     ),                          
   .Dam_q2         (Dam_q2[1:0]     ),                       
   .Ind_Dest_q2    (Ind_Dest_q2     ),                       
   .Ind_Dest_q1    (Ind_Dest_q1     ),                       
   .Ind_SrcA_q0    (Ind_SrcA_q0     ),                       
   .Ind_SrcA_q2    (Ind_SrcA_q2     ),                       
   .Ind_SrcB_q0    (Ind_SrcB_q0     ),
   .Imod_Dest_q0   (Imod_Dest_q0    ),                       
   .Imod_Dest_q2   (Imod_Dest_q2    ),                       
   .Imod_SrcA_q0   (Imod_SrcA_q0    ),                       
   .Imod_SrcB_q0   (Imod_SrcB_q0    ),                       
   .Ind_SrcB_q2    (Ind_SrcB_q2     ),
   .Size_SrcA_q1   (Size_SrcA_q1[1:0]),
   .Size_SrcB_q1   (Size_SrcB_q1[1:0]),
   .Size_SrcA_q2   (Size_SrcA_q2[1:0]),
   .Size_SrcB_q2   (Size_SrcB_q2[2:0]),  // need this for btbc/s
   .Size_Dest_q2   (Size_Dest_q2[1:0]),
   .SigA_q1        (SigA_q1          ),
   .SigA_q2        (SigA_q2          ),                      
   .SigB_q2        (SigB_q2          ),                      
   .SigD_q2        (SigD_q2          ),                      
   .OPsrc32_q0     (OPsrc32_q0[31:0]),                      
   .Ind_Dest_q0    (Ind_Dest_q0      ),                      
   .Dest_addrs_q2  (coreDest_addrs_q2),
   .Dest_addrs_q0  (Dest_addrs_q0   ),                
   .SrcA_addrs_q0  (coreSrcA_addrs_q0),                
   .SrcB_addrs_q0  (SrcB_addrs_q0   ),                
   .SrcA_addrs_q1  (SrcA_addrs_q1   ),                    
   .SrcB_addrs_q1  (SrcB_addrs_q1   ),                    
   .V_q2           (V_q2            ),                      
   .N_q2           (N_q2            ),                      
   .C_q2           (C_q2            ),                      
   .Z_q2           (Z_q2            ),                      
   .V              (V               ),                      
   .N              (N               ),                      
   .C              (C               ),                      
   .Z              (Z               ),                      
   .IRQ            (IRQ             ),                      
   .done           (done            ),                      
   .IRQ_IE         (IRQ_IE          ),                      
   .break_q0       (break_q0        ),                       
   .rddataA_integer(rddataA_integer[63:0]),                  
   .rddataB_integer(rddataB_integer[63:0]),                  
   .mon_write_reg  (mon_writeData_q1[63:0]),              //this is the data to be written during monitor write operation
   .mon_read_reg   (mon_read_reg    ),    //don't care if it writes to read_reg or not
   .ind_mon_read_q0 (ind_mon_read_q0),
   .ind_mon_write_q2(ind_mon_write_q2),                            
   .exc_codeA      (exc_codeA       ),                      
   .exc_codeB      (exc_codeB       ),                      
   .float_rddataA  (float_rddataA   ),
   .float_rddataB  (float_rddataB   ),
   .RM_q1          (RM_q1           ),                       
   .fp_ready_q1    (fp_ready_q1 || FuNN_ready_q1),                             
   .fp_ready_q2    (fp_ready_q2     ),                             
   .RM_Attribute_on(RM_Attribute_on),
   .Away           (Away            ),
   .RM_Attribute   (RM              ),       
   .int_in_service (int_in_service  ),
   .statusRWcollision(statusRWcollision),
   .writeAbort     (writeAbort      ),
   .write_disable  (write_disable   ),
   .ACTM           (ACTM            ),
   .PRNG_ready     (PRNG_ready_q0   ),
   .ready_q0       (ready_q0   )
   );   
   
assign glob_RAM_rddataA = 0;
assign glob_RAM_rddataB = 0;
    
always @(posedge CLK) tableRead_q1 = tableRead_q0; 

SCEultraProgRAM #(.ADDRS_WIDTH(`PSIZE))       //dword addressable for program and table/constant storage
   PRAM0(      //program memory 
   .CLK       (CLK ),
   .wren      (tableWrite_q2 ),  
   .wraddrs   (Dest_addrs_q2[`PSIZE-1:0]),             //writes to program ram are dword in address increments of one
   .wrdata    (wrsrcAdataSext[63:0]),
   .rdenA     (tableRead_q0),
   .rdaddrsA  (SrcA_addrs_q0[`PSIZE-1:0]),
   .rddataA   (tableReadData_q1[63:0]),
   .rdenB     (rdcycl ),
   .rdaddrsB  (pre_PC[`PSIZE-1:0]),
   .rddataB   (Instruction_q0)
   ); 
    
    
triPortBlockRAM_ZeroPage  #(.ADDRS_WIDTH(11)) //reduced to 16K bytes  
    ram0(            //(first 16k bytes) of directly or indirectly addressable memory
   .CLK       (CLK   ),
   .wren      (wrcycl && (Dest_addrs_q2[31:14]==18'b0)),
   .wrsize    (Size_Dest_q2[1:0]),
   .wraddrs   (Dest_addrs_q2[13:0]),
   .wrdata    (wrsrcAdataSext[63:0]),
   .rdenA     (SrcA_addrs_q0[31:14]==18'b0),
   .rdAsize   (Size_SrcA_q0[1:0]),
   .rdaddrsA  (SrcA_addrs_q0[13:0]),
   .rddataA   (priv_RAM_rddataA[63:0]),
   .rdenB     (SrcB_addrs_q0[31:14]==18'b0),                                                       
   .rdBsize   (Size_SrcB_q0[1:0]),
   .rdaddrsB  (SrcB_addrs_q0[13:0]),
   .rddataB   (priv_RAM_rddataB[63:0])
   );  


always @(posedge CLK)
    if (RESET) _3portFatRAM_rdselA_q1 <= 0;
    else _3portFatRAM_rdselA_q1 <= _3portFatRAM_rdselA;

always @(posedge CLK)
    if (RESET) _3portFatRAM_rdselB_q1 <= 0;
    else _3portFatRAM_rdselB_q1 <= _3portFatRAM_rdselB;
   
threePortFatRAMx1024 #(.ADDRS_WIDTH(8))  //256 gob-deep x 128 bytes-wide  (32k bytes total)
    ram1( //second 32k bytes indirect access only  three ports
    .CLK       (CLK   ),
    .wren      (~SigD_q2 && fat_wrdata_sel),
    .wrsize    (Size_Dest_q2[2:0]),
    .wraddrs   (Dest_addrs_q2[14:0]),  //byte address
    .wrdata    (fat_wrsrcAdataSext[1023:0]),
    .rdenA     (fat_rddataA_sel),
    .rdAsize   (Size_SrcA_q0[2:0]),                                                     
    .rdaddrsA  (SrcA_addrs_q0[14:0]),     //byte address                                
    .rddataA   (fat_RAM_rddataA_LO[1023:0]),                                               
    .rdenB     (fat_rddataB_sel),                                                       
    .rdBsize   (Size_SrcB_q0[2:0]),     //byte address
    .rdaddrsB  (SrcB_addrs_q0[14:0]),
    .rddataB   (fat_RAM_rddataB_LO[1023:0])
    );    
    
reg [4:0] FP_Dx0_Inv_Ovf_Unf_Nxact_q2;   
RAM_sig sigStack (
    .CLK     (CLK  ),
    .wren    ((SigD_q2 && fat_wrdata_sel) || fat_push),
    .wraddrs (Dest_addrs_q2[14:0]),
    .wrdata  (SigD_q2 ? wrsrcAdata[4:0] : (fp_sel_q2 ? FP_Dx0_Inv_Ovf_Unf_Nxact_q2 : {1'b0, C_q2, V_q2, N_q2, Z_q2})),
    .rden    ((SigD_q0 && fat_rddataA_sel) || fat_pull),    //use this signal for restore operator
    .rdaddrs (SrcA_addrs_q0[14:0]),
    .rddata  (pulled_signals_q1)
    );                                                               

always @(posedge CLK) FP_Dx0_Inv_Ovf_Unf_Nxact_q2 <= FP_Dx0_Inv_Ovf_Unf_Nxact;
always @(posedge CLK) sig_stk_rden_q1 <= SigD_q0 && fat_rddataA_sel && dest_not_FP_or_Integer;

    
always @(posedge CLK)
    if (RESET) pulled_signals_q2 <= 5'b00000;
    else  pulled_signals_q2 <= pulled_signals_q1; 

always @(posedge CLK)
    if (RESET) begin
        restore_q1 <= 0;
        restore_q2 <= 0;
    end    
    else begin
        restore_q1 <= fat_pull;
        restore_q2 <= restore_q1;
    end

threePortFatRAMx1024 #(.ADDRS_WIDTH(9))  //512 gob-deep x 128 bytes-wide  (64k bytes total)
    ram2( //second 64k bytes indirect access only  three ports
    .CLK       (CLK                    ),
    .wren      (_3portFatRAM_wrsel     ),
    .wrsize    (_3portWRsize[2:0]      ),
    .wraddrs   (_3portWraddrs[15:0]    ),  //byte address
    .wrdata    (_3portWrdata[1023:0]   ),
    .rdenA     (_3portFatRAM_rdselA    ),
    .rdAsize   (_3portRDsizeA[2:0]     ),                                                     
    .rdaddrsA  (_3portRdaddrsA[15:0]   ),  //byte address                                
    .rddataA   (fat_RAM_rddataA_HI[1023:0]),                                               
    .rdenB     (_3portFatRAM_rdselB    ),                                                       
    .rdBsize   (_3portRDsizeB[2:0]     ),  //byte address
    .rdaddrsB  (_3portRdaddrsB[15:0]   ),
    .rddataB   (fat_RAM_rddataB_HI[1023:0])
    );    

reg RDintegerLogicSelA_q1;
wire RDintegerLogicSelA;
assign RDintegerLogicSelA = ~&Dam_q0[1:0] && (SrcA_addrs_q0[31:15]==17'b0) && ((SrcA_addrs_q0[14:8]==7'h7E) || (SrcA_addrs_q0[14:4]==11'h7DF)); 
 
wire RDintegerLogicSelB;
assign RDintegerLogicSelB = ~&Dam_q0[1:0] && (SrcB_addrs_q0[31:15]==17'b0) && ((SrcB_addrs_q0[14:8]==7'h7E) || (SrcB_addrs_q0[14:4]==11'h7DF));   

`ifdef SCE_HAS_INTEGER 
integr_logic integr_logic(
   .CLK         (CLK         ),
   .RESET       (RESET       ),
   .wren        (wrcycl && (Dest_addrs_q2[31:15]==17'b0) && ((Dest_addrs_q2[14:8]==7'h7E) || (Dest_addrs_q2[14:4]==11'h7DF))),    // A[15:12]==4'b1101 && wrcycl && ~Ind_Dest_q2
   .SigD_q2     (SigD_q2     ),
   .Size_Dest_q1(Size_Dest_q1[1:0]),
   .wraddrs     (Dest_addrs_q2[3:0]),    //
   .operatr_q2  (Dest_addrs_q2[11:4]),   
   .oprndA      (wrsrcAdataSext[63:0]),
   .oprndB      (wrsrcBdataSext[63:0]),
   .C           (C           ),
   .V           (V           ),
   .N           (N           ),
   .Z           (Z           ),
   .rdenA       (RDintegerLogicSelA),
   .SigA_q1     (SigA_q1     ),
   .SigA_q2     (SigA_q2     ),
   .Size_SrcA_q1(Size_SrcA_q1[1:0]),
   .rdaddrsA    (SrcA_addrs_q0[3:0]),    //A[11:7] is operator select, A[6:3] is result buffer select
   .operatrA_q0 (SrcA_addrs_q0[11:4]),
   .rddataA     (rddataA_integer),
   .rdenB       (RDintegerLogicSelB),
   .SigB_q1     (SigB_q1),
   .SigB_q2     (SigB_q2),
   .Size_SrcB_q1(Size_SrcB_q1[1:0]),
   .rdaddrsB    (SrcB_addrs_q0[3:0]),    //
   .operatrB_q0 (SrcB_addrs_q0[11:4]),
   .rddataB     (rddataB_integer),
   .ready_q1    (ready_integer_q1),
   .restore_q2  (restore_q2),
   .pulled_signals_q2(pulled_signals_q2[3:0])      //{1'b0, C_q2, V_q2, N_q2, Z_q2}
   );
`else

assign  ready_integer_q1 = 1'b1;
assign  rddataA_integer = 0;
assign  rddataB_integer = 0;
`endif

    
always @(*) begin                    
   if (SigA_q2) 
       case (Size_SrcA_q2)
           3'b000 : if (wrsrcAdata[7]) wrsrcAdataSext[63:0] = {{14{4'hF}}, wrsrcAdata[7:0]};
                    else wrsrcAdataSext[63:0] = wrsrcAdata[63:0];
                    
           3'b001 : if (wrsrcAdata[15]) wrsrcAdataSext[63:0] = {{12{4'hF}}, wrsrcAdata[15:0]};
                    else wrsrcAdataSext[63:0] = wrsrcAdata[63:0];
                   
           3'b010 : if (wrsrcAdata[31]) wrsrcAdataSext[63:0] = {{8{4'hF}}, wrsrcAdata[31:0]};
                    else wrsrcAdataSext[63:0] = wrsrcAdata[63:0];
                                        
           default: wrsrcAdataSext[63:0] = wrsrcAdata[63:0]; 
       endcase
    else  wrsrcAdataSext[63:0] = wrsrcAdata[63:0];
end                           

always @(*) begin                    
   if (SigB_q2) 
       case (Size_SrcB_q2)
           3'b000 : if (wrsrcBdata[7]) wrsrcBdataSext[63:0] = {{14{4'hF}}, wrsrcBdata[7:0]};
                    else wrsrcBdataSext[63:0] = wrsrcBdata[63:0];
                    
           3'b001 : if (wrsrcBdata[15]) wrsrcBdataSext[63:0] = {{12{4'hF}}, wrsrcBdata[15:0]};
                    else wrsrcBdataSext[63:0] = wrsrcBdata[63:0];
                   
           3'b010 : if (wrsrcBdata[31]) wrsrcBdataSext[63:0] = {{8{4'hF}}, wrsrcBdata[31:0]};
                    else wrsrcBdataSext[63:0] = wrsrcBdata[63:0];
                                        
           default: wrsrcBdataSext[63:0] = wrsrcBdata[63:0]; 
       endcase
    else  wrsrcBdataSext[63:0] = wrsrcBdata[63:0];
end                           

always @(posedge CLK) RESET <= RESET_OUT || RESET_IN;

always @(posedge CLK or posedge RESET) begin                                                                     
   if (RESET) begin                                                                                             
       // state 1 fetch                                                                                         
       pc_q1               <= `PCWIDTH'h100;                                                                               
       Dam_q1[1:0]         <= 2'b00;                         
       SrcA_addrs_q1       <= 32'b0;                                                                                
       SrcB_addrs_q1       <= 32'b0;                                                              
       OPdest_q1           <= 0;                                                                        
       OPsrcA_q1           <= 0;                                                                        
       OPsrcB_q1           <= 0;                                                                        
       RM_q1[1:0]          <= 0; 
       NN_Mode_q1[1:0]     <= 0; 
       SigD_q1             <= 1'b0;
       Size_Dest_q1[2:0]   <= 0;
       Ind_Dest_q1         <= 1'b0;
       Imod_Dest_q1        <= 1'b0;
       SigA_q1             <= 1'b0;
       Size_SrcA_q1[2:0]   <= 0;
       Ind_SrcA_q1         <= 1'b0; 
       SigB_q1             <= 1'b0;
       Size_SrcB_q1[2:0]   <= 0;
       Ind_SrcB_q1         <= 1'b0; 
       OPsrc32_q1          <= 32'b0; 
       immediate16_q1      <= 0;                                                                                                             
                                                                                                                 
       // state2 read                                                                                             
       pc_q2               <= `PCWIDTH'h100;                                                                 
       Dam_q2[1:0]         <= 2'b00;           
       SrcA_addrs_q2       <= 32'b0;                                                                         
       SrcB_addrs_q2       <= 32'b0;                                                       
       OPdest_q2           <= 0;                                                              
       OPsrcA_q2           <= 0;                                                              
       OPsrcB_q2           <= 0;                                                              
       RM_q2[1:0]          <= 0;  
       NN_Mode_q2[1:0]     <= 0; 
       SigD_q2             <= 1'b0;
       Size_Dest_q2[2:0]   <= 0;
       Ind_Dest_q2         <= 1'b0;
       Imod_Dest_q2        <= 1'b0;
       SigA_q2             <= 1'b0;
       Size_SrcA_q2[2:0]   <= 0;
       Ind_SrcA_q2         <= 1'b0; 
       SigB_q2             <= 1'b0;
       Size_SrcB_q2[2:0]   <= 0;
       Ind_SrcB_q2         <= 1'b0; 
                                                                                                     
       STATE <= 4'b0000;                                                                               
                                                                                                       
       wrsrcAdata <= 0;
       wrsrcBdata <= 0;         

       fp_sel_q1 <= 1'b0;                                                  
       fp_ready_q2 <= 1'b1;
       fp_sel_q2 <= 1'b0;                                                  
       
       SrcA_addrs_q2       <= 32'b0;
       SrcB_addrs_q2       <= 32'b0;
               
       C_q2 <= 1'b0;
       V_q2 <= 1'b0;
       N_q2 <= 1'b0;
       Z_q2 <= 1'b0;
              
       RDintegerLogicSelA_q1 <= 0;
              
       write_collision_os <= 1'b0;
       write_collision_os_q1 <= 1'b0;
       
       fat_wrsrcAdataSext <= 0;    
       fat_wrsrcBdataSext <= 0;  
       fat_rddataA_sel_q1 <= 0;
       fat_rddataB_sel_q1 <= 0;
       toDecCharRddataA_sel_q1 <= 0;
       toDecCharRddataB_sel_q1 <= 0;
              
   end                                                                                                          
   else begin                                                                                                   
       STATE <= {1'b1, STATE[3:1]};    //rotate right 1 into msb  (shift right)
       fp_ready_q2        <= fp_ready_q1 &&  FuNN_ready_q1;
       write_collision_os <= write_collision ;
       write_collision_os_q1 <= write_collision_os;
       
       toDecCharRddataA_sel_q1 <= toDecCharRddataA_sel;
       toDecCharRddataB_sel_q1 <= toDecCharRddataB_sel;                            
                                                                                   
       fat_rddataA_sel_q1 <= fat_rddataA_sel;
       fat_rddataB_sel_q1 <= fat_rddataB_sel;
              
       fat_wrsrcAdataSext <= (fat_rddataA_sel_q1 ||  FuNNrdenA_q1 || _3portFatRAM_rdselA_q1) ? fat_RAM_rddataA : (toDecCharRddataA_sel_q1 ? {648'b0, toDecCharRddataA} : {960'b0, ((XPUSH_q2||XPUSHD_q2) ? RISC_V_RAMrddataA : rdSrcAdata)});
       fat_wrsrcBdataSext <= (fat_rddataB_sel_q1 ||  FuNNrdenB_q1 || _3portFatRAM_rdselB_q1) ? fat_RAM_rddataB : (toDecCharRddataB_sel_q1 ? {648'b0, toDecCharRddataB} : {960'b0,            (XPUSHD_q2  ? RISC_V_RAMrddataB : rdSrcAdata)});

       
       RDintegerLogicSelA_q1 <= RDintegerLogicSelA;
       
       if (RDintegerLogicSelA_q1) begin
           C_q2 <= C_q1;
           V_q2 <= V_q1;
           N_q2 <= N_q1;
           Z_q2 <= Z_q1;
       end
    
          RM_q1[1:0]          <= RM_q0[1:0]          ;
          NN_Mode_q1[1:0]     <= NN_Mode_q0[1:0]     ;
          pc_q1               <= PC                  ; 
          Dam_q1[1:0]         <= Dam_q0[1:0]         ;                 
          SrcA_addrs_q1       <= SrcA_addrs_q0       ; 
          SrcB_addrs_q1       <= SrcB_addrs_q0       ; 
          OPdest_q1           <= OPdest_q0           ;
          OPsrcA_q1           <= OPsrcA_q0           ;
          OPsrcB_q1           <= OPsrcB_q0           ;
          OPsrc32_q1          <= OPsrc32_q0          ;
          immediate16_q1      <= immediate16_q0      ;
          
          fp_sel_q1           <= fp_sel_q0           ;
          fp_sel_q2           <= fp_sel_q1           ;
          
          RM_q2               <= RM_q1               ;
          NN_Mode_q2          <= NN_Mode_q1          ;
          pc_q2               <= pc_q1               ;  
          SrcA_addrs_q2       <= SrcA_addrs_q1       ; 
          SrcB_addrs_q2       <= SrcB_addrs_q1       ; 
          OPdest_q2           <= OPdest_q1           ;
          OPsrcA_q2           <= OPsrcA_q1           ;
          OPsrcB_q2           <= OPsrcB_q1           ;
          
          SigD_q1             <= SigD_q0             ;
          Size_Dest_q1        <= Size_Dest_q0        ;
          Ind_Dest_q1         <= Ind_Dest_q0         ;
          Imod_Dest_q1        <= Imod_Dest_q0        ;
          SigA_q1             <= SigA_q0             ;
          Size_SrcA_q1        <= Size_SrcA_q0        ;
          Ind_SrcA_q1         <= Ind_SrcA_q0         ;
          SigB_q1             <= SigB_q0             ;
          Size_SrcB_q1        <= Size_SrcB_q0        ;
          Ind_SrcB_q1         <= Ind_SrcB_q0         ;
                                                     
          SigD_q2             <= SigD_q1             ;
          Size_Dest_q2        <= Size_Dest_q1        ;
          Ind_Dest_q2         <= Ind_Dest_q1         ;
          Imod_Dest_q2        <= Imod_Dest_q1        ;
          SigA_q2             <= SigA_q1             ;
          Size_SrcA_q2        <= Size_SrcA_q1        ;
          Ind_SrcA_q2         <= Ind_SrcA_q1         ;
          SigB_q2             <= SigB_q1             ;
          Size_SrcB_q2        <= Size_SrcB_q1        ;
          Ind_SrcB_q2         <= Ind_SrcB_q1         ;


          case(Dam_q1)     //MOV
              2'b00 : begin    // both srcA and srcB are either direct or indirect
                         wrsrcAdata <= (XPUSH_q2||XPUSHD_q2) ? RISC_V_RAMrddataA : rdSrcAdata;  //rdSrcA expects data here to be zero-extended to 64 bits           
                         wrsrcBdata <= XPUSHD_q2 ? RISC_V_RAMrddataB : rdSrcAdata;  //rdSrcB expects data here to be zero-extended to 64 bits
                      end
              2'b01 : begin   //srcA is direct or indirect and srcB is 8 or 16-bit immediate
                         wrsrcAdata <= rdSrcAdata;     //direct or indirect srcA
                         wrsrcBdata <= {48'b0, immediate16_q1};    //rdSrcB expects data here to be zero-extended to 64 bits
                      end
              2'b10 : begin  //srcA is table-read and srcB is direct or indirect 
                         wrsrcAdata <= rdSrcAdata;     //rdSrcA expects data here to be zero-extended to 64 bits        
                         wrsrcBdata <= rdSrcBdata;     //rdSrcB expects data here to be zero-extended to 64 bits
                      end
              2'b11 : begin //32-bit immediate       
                         wrsrcAdata <= {32'h0000_0000, OPsrc32_q1[31:0]};   //rdSrcA expects data here to be zero-extended to 64 bits
                         wrsrcBdata <= 64'b0;     
                      end
          endcase  
         
  end             
end

endmodule
