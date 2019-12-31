// H8IntegerPart.v
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


module H8IntegerPart (
    CLK          , 
    RESET        , 
    wren         ,  
    wrdata       ,  
    bcdIntegerOut,
    fractMask    ,
    fractionOnly 
    );

input CLK;
input RESET;
input wren;
input [15:0]  wrdata;
output [26:0] bcdIntegerOut;
output [8:0] fractMask;
output fractionOnly;

reg [26:0] intFinalq;
reg roundit_q;
reg [2:0] chafCarries;
reg [7:0] chafFinalq;

wire [26:0] intD8_intD7;   
wire [26:0] intD6_intD5;
wire [26:0] intD4_intD3;   
wire [26:0] intD2_intD1;
wire [26:0] intD0;

wire [26:0] intD8_intD7__intD6_intD5_intD0;
wire [26:0] intD4_intD3__intD2_intD1;

wire [26:0] bcdIntegerOut;

wire [9:0] chafD7_chafD6;
wire [9:0] chafD5_chafD4;
wire [9:0] chafD3_chafD2;
wire [9:0] chafD1_chafD0;

wire [9:0] chafD7_chafD6__chafD5_chafD4;  
wire [9:0] chafD3_chafD2__chafD1_chafD0;

wire [10:0] chafFinal;

wire [2:0] GRS;
assign GRS = {chafFinalq[7:6], |chafFinalq[5:0]};
  
wire roundit;
assign roundit = ((GRS==3'b100) && (intFinalq[0])) || (GRS[2] && |GRS[1:0]);

wire [6:0] biasedExp;
wire [7:0] mant;
wire zeroIn;

wire [26:0] IntWeight;
wire [7:0] intMask;
wire [8:0] fractMask;
wire fractionOnly;

assign biasedExp = wrdata[14:8];
assign mant = intMask;
assign zeroIn = ~|wrdata[14:0];

ROMweightsInt_H8 weightInt(
    .CLK      (CLK      ),
    .RESET    (RESET    ),
    .rden     (wren     ),
    .rdaddrs  (biasedExp[6:0]),
    .mantissa (wrdata[7:0]),
    .IntWeight(IntWeight),
    .intMask  (intMask  ),
    .fractMask(fractMask),
    .zeroIn   (zeroIn   ),
    .fractionOnly(fractionOnly)
    );    

assign intD8_intD7 =                     IntWeight              + (mant[7] ? { 1'b0, IntWeight[26: 1]} : 0); 
assign intD6_intD5 = ((mant[6] ? { 2'b0, IntWeight[26: 2]} : 0) + (mant[5] ? { 3'b0, IntWeight[26: 3]} : 0));
assign intD4_intD3 = ((mant[4] ? { 4'b0, IntWeight[26: 4]} : 0) + (mant[3] ? { 5'b0, IntWeight[26: 5]} : 0));
assign intD2_intD1 = ((mant[2] ? { 6'b0, IntWeight[26: 6]} : 0) + (mant[1] ? { 7'b0, IntWeight[26: 7]} : 0));
assign intD0       =  (mant[0] ? { 8'b0, IntWeight[26: 8]} : 0) ;

assign intD8_intD7__intD6_intD5_intD0 = intD8_intD7 + intD6_intD5 + intD0;
assign intD4_intD3__intD2_intD1 = intD4_intD3 + intD2_intD1;

assign chafD7_chafD6 = (mant[ 7] ? {IntWeight[0  ],  7'b0} : 0) + (mant[ 6] ? {IntWeight[1:0],  6'b0} : 0);  
assign chafD5_chafD4 = (mant[ 5] ? {IntWeight[2:0],  5'b0} : 0) + (mant[ 4] ? {IntWeight[3:0],  4'b0} : 0);
assign chafD3_chafD2 = (mant[ 3] ? {IntWeight[4:0],  3'b0} : 0) + (mant[ 2] ? {IntWeight[5:0],  2'b0} : 0);  
assign chafD1_chafD0 = (mant[ 1] ? {IntWeight[6:0],  1'b0} : 0) + (mant[ 0] ? {IntWeight[7:0]} : 0) ;
        
assign chafD7_chafD6__chafD5_chafD4 = chafD7_chafD6 + chafD5_chafD4;
assign chafD3_chafD2__chafD1_chafD0 = chafD3_chafD2 + chafD1_chafD0;
        
assign chafFinal = chafD7_chafD6__chafD5_chafD4 + chafD3_chafD2__chafD1_chafD0;

always @(posedge CLK) intFinalq <= intD8_intD7__intD6_intD5_intD0 + intD4_intD3__intD2_intD1;

assign bcdIntegerOut = intFinalq + chafCarries + roundit_q;

always @(posedge CLK) begin
    if (RESET) begin
        roundit_q   <= 0;
        chafCarries <= 0;
        chafFinalq  <= 0;
    end
    else begin
        roundit_q <= roundit;
        chafCarries <= chafFinal[10:8];
        chafFinalq <= chafFinal[7:0];
    end
end

endmodule






