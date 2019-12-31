// SCE_breakpoints.v
 
// Author:  Jerry D. Harthcock
// Version:  1.03  June 17, 2018
// Copyright (C) 2018.  All rights reserved.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                  //
//                                                Open-Source                                                       //
//                                        SYMPL 64-Bit OpCodeless CPU                                               //
//                                Evaluation and Product Development License                                        //
//                                                                                                                  //
//                                                                                                                  //
// Open-source means that this source code may be freely downloaded, copied, modified, distributed and used in      //
// accordance with the terms and conditons of the licenses provided herein.                                         //
//                                                                                                                  //
// Provided that you comply with all the terms and conditions set forth herein, Jerry D. Harthcock ("licensor"),    //
// the original author and exclusive copyright owner of this SYMPL 64-Bit OpCodeless CPU and related development    //
// software ("this IP") hereby grants recipient of this IP ("licensee"), a world-wide, paid-up, non-exclusive       //
// license to implement this IP within the programmable fabric of Xilinx, Intel, MicroSemi or Lattice               //
// Semiconductor brand FPGAs only and used only for the purposes of evaluation, education, and development of end   //
// products and related development tools.  Furthermore, limited to the purposes of prototyping, evaluation,        //
// characterization and testing of implementations in a hard, custom or semi-custom ASIC, any university or         //
// institution of higher education may have their implementation of this IP produced for said limited purposes at   //
// any foundary of their choosing provided that such prototypes do not ever wind up in commercial circulation,      //
// with such license extending to said foundary and is in connection with said academic pursuit and under the       //
// supervision of said university or institution of higher education.                                               //            
//                                                                                                                  //
// Any copying, distribution, customization, modification, or derivative work of this IP must include an exact copy //
// of this license and original copyright notice at the very top of each source file and any derived netlist, and,  //
// in the case of binaries, a printed copy of this license and/or a text format copy in a separate file distributed //
// with said netlists or binary files having the file name, "LICENSE.txt".  You, the licensee, also agree not to    //
// remove any copyright notices from any source file covered or distributed under this Evaluation and Product       //
// Development License.                                                                                             //
//                                                                                                                  //
// LICENSOR DOES NOT WARRANT OR GUARANTEE THAT YOUR USE OF THIS IP WILL NOT INFRINGE THE RIGHTS OF OTHERS OR        //
// THAT IT IS SUITABLE OR FIT FOR ANY PURPOSE AND THAT YOU, THE LICENSEE, AGREE TO HOLD LICENSOR HARMLESS FROM      //
// ANY CLAIM BROUGHT BY YOU OR ANY THIRD PARTY FOR YOUR SUCH USE.                                                   //
//                                                                                                                  //
//                                               N O T I C E                                                        //
//                                                                                                                  //
// Certain implementations of this IP involving certain floating-point operators may comprise IP owned by certain   //
// contributors and developers at FloPoCo.  FloPoCo's licensing terms can be found at this website:                 //
//                                                                                                                  //
//    http://flopoco.gforge.inria.fr                                                                                //
//                                                                                                                  //
// Licensor reserves all his rights, including, but in no way limited to, the right to change or modify the terms   //
// and conditions of this Evaluation and Product Development License anytime without notice of any kind to anyone.  //
// By using this IP for any purpose, you agree to all the terms and conditions set forth in this Evaluation and     //
// Product Development License.                                                                                     //
//                                                                                                                  //
// This Evaluation and Product Development License does not include the right to sell products that incorporate     //
// this IP or any IP derived from this IP. If you would like to obtain such a license, please contact Licensor.     //           
//                                                                                                                  //
// Licensor can be contacted at:  SYMPL.gpu@gmail.com                                                               //
//                                                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 `timescale 1ns/100ps

module SCE_breakpoints (
    CLK,
    RESET_IN,
    RESET_OUT,
    Instruction_q0,
    Instruction_q0_del,
    
    break_q0,
    break_q1,
    break_q2,
    ind_mon_read_q0,
    ind_mon_write_q2,
    mon_write_addrs_q2,
    mon_read_addrs,
    mon_writeData_q1,
    monRDreq,
    monWRreq_q1,
    XPULL_q2,
    XPUSH_q1,
    XPUSH_q2,
    XPUSHD_q1,
    XPUSHD_q2,
    monRWsize_q1,
    monRWsize_q2,
    
    frc_brk,
    broke,
    skip_cmplt,
    swbreakDetect,
    
    RISC_V_ready,
    RISC_V_instr, 
    RISC_V_cancel,
    
    x31,          
    x30,          
    x29,          
    SCE_sel          
    );

input CLK;
input RESET_IN;
output RESET_OUT;
input  [63:0] Instruction_q0;
output [63:0] Instruction_q0_del;

output break_q0;
output break_q1;
output break_q2;
output ind_mon_read_q0;
output ind_mon_write_q2;
output [31:0] mon_write_addrs_q2;
output [31:0] mon_read_addrs;
output [63:0] mon_writeData_q1; 
output monRDreq;    
output monWRreq_q1;
output XPULL_q2;
output XPUSH_q1;
output XPUSH_q2;
output XPUSHD_q1;
output XPUSHD_q2;
output [2:0] monRWsize_q1;
output [2:0] monRWsize_q2;

output frc_brk;
output broke;
output skip_cmplt;
output swbreakDetect;

input RISC_V_ready;
input [31:0] RISC_V_instr; 
input        RISC_V_cancel;
    
input [31:0] x31;          
input [31:0] x30;          
input [31:0] x29;          
input SCE_sel;          

parameter MON_ADDRS = 32'h00007FEB;
parameter SWBREAK   = 64'h127FF30000000000;

reg XFRCBRK;
reg XFRCRST;

reg break_q0;
reg break_q1;
reg break_q2;

reg [1:0] break_state;

reg broke;

reg skip;

reg skip_cmplt;

reg ind_mon_wr_q1;
reg ind_mon_wr_q2;
reg [63:0] mon_writeData_q1;
reg monWRreq_q1;
reg [31:0] mon_write_addrs_q1;
reg [31:0] mon_write_addrs_q2;
reg XPULL_q2;
reg XPUSH_q2;
reg XPUSHD_q2;
reg [2:0] monRWsize_q2;
reg [2:0] monRWsize_q1;

reg  swbreakDetect_q1;
reg  swbreakDetect_q2;

wire swbreakDetect;

wire monRDreq;
wire monWRreq;
wire frc_brk;
wire sstep;
wire RESET_OUT;
wire RESET;
    
wire [2:0] mon_write_size;
wire [2:0] mon_read_size;
//reg SigD_q1;
reg SigA_q1;

wire mon_SigA;
wire [31:0] mon_read_addrs;
wire [31:0] mon_write_addrs;

wire any_break_det;

wire [63:0] Instruction_q0_del;
wire [63:0] monitor_instruction;

wire ind_mon_read;
wire ind_mon_write;
wire ind_mon_read_q0;
wire ind_mon_write_q2;
                                                                                                         
wire XLQU_q1;   
wire XLDU_q1;   
wire XLWU_q1;   
wire XLHU_q1;   
wire XLBU_q1;   
wire XSQ_q1;    
wire XSD_q1;    
wire XSW_q1;    
wire XSH_q1;    
wire XSB_q1;    
wire XPUSH_q1;  
wire XPULL_q1;  
wire XPUSHD_q1;
wire XFRCBRK_q1;
wire XCLRBRK_q1;
wire XFRCRST_q1;
wire XCLRRST_q1;
wire XSSTEP_q1; 
wire XSTATUS_q1;
wire MREQ_q0;  


assign swbreakDetect = (Instruction_q0_del==SWBREAK) || swbreakDetect_q1 || swbreakDetect_q2;

always @(posedge CLK) begin
    swbreakDetect_q1 <= (Instruction_q0_del==SWBREAK);
    swbreakDetect_q2 <= swbreakDetect_q1;
end    

assign frc_brk = XFRCBRK;
assign sstep = XSSTEP_q1;
assign RESET_OUT = XFRCRST;
assign RESET = RESET_OUT || RESET_IN;

assign monRDreq = XLQU_q1 || XLDU_q1 || XLWU_q1 || XLHU_q1 || XLBU_q1 || XPULL_q1;
assign monWRreq = XSQ_q1 || XSD_q1 || XSW_q1 || XSH_q1 || XSB_q1 || XPUSH_q1 ||XPUSHD_q1;
assign ind_mon_read  = monRDreq && |x29[31:15];                                                                                       
assign ind_mon_write = monWRreq && |x29[31:15];
assign ind_mon_read_q0  = ind_mon_read  && break_q0;
assign ind_mon_write_q2 = ind_mon_wr_q2 && break_q2;

assign mon_write_size = monWRreq ? monRWsize_q1 : 3'b011;
assign mon_read_size = monRDreq ? monRWsize_q1 : 3'b011;
assign mon_SigA = monRDreq ? SigA_q1 : 1'b0;
assign mon_read_addrs = monRDreq ? x29[31:0] : monWRreq ? MON_ADDRS : 32'b0;  
assign mon_write_addrs = monWRreq ? x29[31:0] : monRDreq ? MON_ADDRS : 32'b0;  
                                                                                              
assign any_break_det = frc_brk || broke;
                       
assign monitor_instruction = {5'b0000_0, mon_write_size, ind_mon_write, mon_write_addrs[14:0], mon_SigA, mon_read_size, ind_mon_read, mon_read_addrs[14:0], 5'b00110, 15'b0};    
assign Instruction_q0_del = (break_q0 && ~RISC_V_cancel) ?  monitor_instruction : Instruction_q0;  

always @(*)
    if (XLDU_q1||XSD_q1) {SigA_q1, monRWsize_q1} = 4'b0011;
    else if (XLWU_q1||XSW_q1) {SigA_q1, monRWsize_q1} = 4'b0010;
    else if (XLHU_q1||XSH_q1) {SigA_q1, monRWsize_q1} = 4'b0001;
    else if (XLBU_q1||XSB_q1) {SigA_q1, monRWsize_q1} = 4'b0000;
    else if (XPUSH_q1||XPULL_q1||XPUSHD_q1) {SigA_q1, monRWsize_q1} = x31[15:12];
    else  {SigA_q1, monRWsize_q1} = 4'b0100;
 
RISC_V_FUSED_INSTR fused_instr(
    .CLK          (CLK          ),
    .RESET        (RESET        ),
    .risc_V_ready (RISC_V_ready ),
    .risc_V_instr (RISC_V_instr ),
    .risc_V_cancel(RISC_V_cancel),
    .SCE_sel      (SCE_sel      ),
    .XLQU_q1      (XLQU_q1      ),
    .XLDU_q1      (XLDU_q1      ),
    .XLWU_q1      (XLWU_q1      ),
    .XLHU_q1      (XLHU_q1      ),
    .XLBU_q1      (XLBU_q1      ),
    .XSQ_q1       (XSQ_q1       ),
    .XSD_q1       (XSD_q1       ),
    .XSW_q1       (XSW_q1       ),
    .XSH_q1       (XSH_q1       ),
    .XSB_q1       (XSB_q1       ),
    .XPUSH_q1     (XPUSH_q1     ),
    .XPULL_q1     (XPULL_q1     ),
    .XPUSH_q0     (             ),
    .XPULL_q0     (             ),
    .XPUSHD_q1    (XPUSHD_q1    ),
    .XPUSHD_q0    (             ),
    .XFRCBRK_q1   (XFRCBRK_q1   ),
    .XCLRBRK_q1   (XCLRBRK_q1   ),
    .XFRCRST_q1   (XFRCRST_q1   ),
    .XCLRRST_q1   (XCLRRST_q1   ),
    .XSSTEP_q1    (XSSTEP_q1    ),
    .XSTATUS_q1   (XSTATUS_q1   ),
    .MREQ_q0      (MREQ_q0      )
    );

always @(posedge CLK)
    if (RESET) XFRCBRK <= 1'b1;
    else if (XFRCBRK_q1) XFRCBRK <= 1'b1;
    else if (XCLRBRK_q1) XFRCBRK <= 1'b0;

always @(posedge CLK or posedge RESET_IN)
    if (RESET_IN) XFRCRST <= 1'b0;
    else if (XFRCRST_q1) XFRCRST <= 1'b1;
    else if (XCLRRST_q1) XFRCRST <= 1'b0;

always @(posedge CLK) begin
    ind_mon_wr_q1 <= ind_mon_write;
    ind_mon_wr_q2 <= ind_mon_wr_q1;
    mon_write_addrs_q1 <= mon_write_addrs;
    mon_write_addrs_q2 <= mon_write_addrs_q1;
    
    mon_writeData_q1 <= {x31, x30};
    monWRreq_q1     <= monWRreq;
    XPULL_q2 <= XPULL_q1;
    XPUSH_q2 <= XPUSH_q1;
    XPUSHD_q2 <= XPUSHD_q1;
    monRWsize_q2 <= monRWsize_q1;
end    
                                                                                                                  
always @(posedge CLK) begin
    if (RESET) begin                                                                                               
        break_q0 <= 1'b0;                                                                                          
        break_q1 <= 1'b0;                                                                                          
        break_q2 <= 1'b0;                                                                                          
    end
    else begin                                                                                                     
        break_q0 <= (any_break_det && ~skip) || MREQ_q0; 
        break_q1 <= break_q0 && ~RISC_V_cancel;
        break_q2 <= break_q1;
    end                 
end   

always @(posedge CLK) begin
    if (RESET) begin
        broke <= 1'b0;
        break_state <=2'b00;
        skip <= 1'b0;
        skip_cmplt <= 1'b0;
    end
    else begin
        case(break_state) 
            2'b00 : begin
                        skip_cmplt <= 1'b0;
                        if (frc_brk) begin 
                            broke <= 1'b1;
                            break_state <= 2'b01;
                        end
                    end    
            2'b01 : begin
                        skip_cmplt <= 1'b0;
                        if (sstep) begin
                            skip <= 1'b1;
                            break_state <= 2'b10;
                        end
                    end    
            2'b10 : begin
                        skip <= 1'b0;
                        skip_cmplt <= 1'b1;
                        if (~sstep) begin
                            if (~frc_brk) begin
                                broke <= 1'b0;
                                break_state <= 2'b00;
                            end
                            else break_state <= 2'b01; 
                        end    
                    end
          default : begin
                        broke <= 1'b0;
                        break_state <=2'b00;
                        skip <= 1'b0;
                        skip_cmplt <= 1'b0;
                    end    
                                    
        endcase
    end
end   


endmodule
