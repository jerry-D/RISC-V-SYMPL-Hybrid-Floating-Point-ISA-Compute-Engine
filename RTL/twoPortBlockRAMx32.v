//twoPortBlockRAMx32.v
`timescale 1ns/100ps

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


module twoPortBlockRAMx32 #(parameter ADDRS_WIDTH = 11) (
    CLK,
    wren,
    wrsize,
    wraddrs,
    wrdata,
    rdenA,
    rdAsize,
    rdaddrsA,
    rddataA);    

input  CLK;
input  wren;
input [1:0] wrsize;
input  [ADDRS_WIDTH+2:0] wraddrs; 
input  [31:0] wrdata;                                                    
input  rdenA;                                                                      
input [1:0] rdAsize;
input  [ADDRS_WIDTH+2:0] rdaddrsA;
output [31:0] rddataA;                                     

reg [31:0] rddataA_aligned;

wire [31:0] rddataAq;                                                                                                            
wire [31:0] rddataA;                                                                                                            
                                                                                                          
reg [3:0] byte_sel;
reg [3:0] word_rdA_sel;                                                                              
reg [31:0] wrdata_aligned; 
                                                                                                     
wire [3:0] word_wr_sel;                                                                              
assign word_wr_sel = {wrsize[1:0],  wraddrs[1:0]};

wire [ADDRS_WIDTH-1:0] wraddrs_aligned;
//assign wraddrs_aligned = wraddrs[13:3];
assign wraddrs_aligned = wraddrs[13:2];
 
wire [ADDRS_WIDTH-1:0] rdaddrsA_aligned;
//assign rdaddrsA_aligned = rdaddrsA[13:3];
assign rdaddrsA_aligned = rdaddrsA[13:2];

assign rddataA =  rddataA_aligned;                                                                                                            

blockRAMx32SDP  #(.ADDRS_WIDTH(ADDRS_WIDTH))
  DataRAM_A (   
    .CLK      (CLK     ),
    .wren     (wren    ),
    .bwren    (byte_sel),
    .wraddrs  (wraddrs_aligned ),
    .wrdata   (wrdata_aligned),
    .rden     (rdenA   ),
    .rdaddrs  (rdaddrsA_aligned),
    .rddata   (rddataAq)
    );    

always@(*)                                                                                           
    case(word_rdA_sel)                                                                                
        4'b00_00 : rddataA_aligned = {24'b0, rddataAq[7:0]};       //bytes                    
        4'b00_01 : rddataA_aligned = {24'b0, rddataAq[15:8]};                           
        4'b00_10 : rddataA_aligned = {24'b0, rddataAq[23:16]};  
        4'b00_11 : rddataA_aligned = {24'b0, rddataAq[31:24]};   
        
        4'b01_00, 
        4'b01_01 : rddataA_aligned = {16'b0, rddataAq[15:0]};         //half-words
        4'b01_10,   
        4'b01_11 : rddataA_aligned = {16'b0, rddataAq[31:16]}; 
         default : rddataA_aligned = rddataAq[31:0];                  //words
    endcase
    
always@(*)                                                                                           
    case(word_wr_sel)                                                                                
        4'b00_00 : wrdata_aligned = {24'b0, wrdata[7:0]};            //bytes                    
        4'b00_01 : wrdata_aligned = {16'b0, wrdata[7:0], 8'h00};                          
        4'b00_10 : wrdata_aligned = { 8'b0, wrdata[7:0], 16'h0000}; 
        4'b00_11 : wrdata_aligned = {wrdata[7:0], 24'b0};  
        
        4'b01_00, 
        4'b01_01 : wrdata_aligned = {16'b0, wrdata[15:0]};         //half-words
        4'b01_10, 
        4'b01_11 : wrdata_aligned = {wrdata[15:0], 16'b0};  
         default : wrdata_aligned = wrdata[31:0];                  //words
    endcase

always@(*)          
        case(word_wr_sel)
            4'b00_00 : byte_sel = 4'b0001;        //bytes
            4'b00_01 : byte_sel = 4'b0010;
            4'b00_10 : byte_sel = 4'b0100;
            4'b00_11 : byte_sel = 4'b1000;
            
            4'b01_00, 
            4'b01_01 : byte_sel = 4'b0011;        //half-words
            4'b01_10,  
            4'b01_11 : byte_sel = 4'b1100;
             default : byte_sel = 4'b1111;        //words
        endcase

always @(posedge CLK) begin
     word_rdA_sel <= {rdAsize[1:0],  rdaddrsA[1:0]};
end

endmodule
