//FMUL711.v
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

module FMUL711noClk (
//    CLK,
    A,
    GRSinA,
    B,
    GRSinB,
    R,
    GRSout,
    except
    );

//input CLK;
input [15:0] A;
input [2:0] GRSinA;
input [15:0] B;
input [2:0] GRSinB;
output [15:0] R;
output [2:0] GRSout;
output [4:0] except;

reg sign;
reg [7:0] EXP;        //exponents are added so allow for carry
reg [8:0] normProd;   //includes "hidden" bit
wire [7:0] fraction;
reg [2:0] GRSout;
reg [2:0] GRS;

wire [6:0] expA;
wire [6:0] expB;
wire signA;
wire signB;
wire [4:0] except;

assign expA = A[14:8];
assign expB = B[14:8];
assign signA = A[15];
assign signB = B[15];

reg [15:0] R;
reg [2:0] Rsel;
reg [15:0] theNaN_del;
wire [7:0] expAB;
wire [17:0] intrmProd;       //9bits * 9bits = 18bits
wire AisZero;
wire BisZero;
wire AisInf;
wire BisInf;
wire AisNaN;
wire BisNaN;
wire [15:0] theNaN;
wire anInputIsNaN;
wire anInputIsInf;

reg invalid;
wire divX0;
wire overflow;
wire underflow;
wire inexact;
wire inputIsInvalid;


assign AisInf = &A[14:8] && ~|{A[7:0], GRSinA[2:0]};
assign BisInf = &B[14:8] && ~|{B[7:0], GRSinB[2:0]};
assign AisNaN = &A[14:8] &&  |{A[6:0], GRSinA[2:0]};
assign BisNaN = &B[14:8] &&  |{B[6:0], GRSinB[2:0]};
assign theNaN = AisNaN ? A : B;
assign anInputIsNaN = AisNaN || BisNaN;
assign anInputIsInf = AisInf || BisInf;

assign inputIsInvalid = (AisZero && BisInf) || (BisZero && AisInf);
assign divX0 = 0;
assign underflow = ~|EXP;
assign overflow = &EXP;
assign inexact = |GRS;
assign except = {divX0, invalid, overflow, underflow && inexact, inexact};

assign expAB = (AisZero || BisZero) ? 0 : ((expA + expB) - 63);
assign AisZero = ~|A[14:0];
assign BisZero = ~|B[14:0];
assign intrmProd = (AisZero || BisZero) ? 0 : {1'b1, A[7:0]} * {1'b1, B[7:0]};
assign fraction = normProd[7:0];

always @(*)
    casex(Rsel)
        3'b1xx : {R, GRSout} = {sign, 7'h7F, 1'b1, 7'h1E, GRS};   // invalid input
        3'b01x : {R, GRSout} = {theNaN_del, GRS};                 // an input is NaN
        3'b001 : {R, GRSout} = {sign, 15'h7F00, GRS};             // infinite or overflow
       default : {R, GRSout} = {sign, EXP[6:0], normProd[7:0], GRS};
    endcase    

/*
always @(posedge CLK) begin
    invalid <= inputIsInvalid;
    theNaN_del <= theNaN;
    Rsel <= {inputIsInvalid, anInputIsNaN, anInputIsInf || (intrmProd[17] ? &(expAB + 1) : &expAB};
    sign <= (AisZero || BisZero) ? 0 : (signA ^ signB);
    if (intrmProd[17]) begin
        normProd <= intrmProd[17:9];
        GRS <= {intrmProd[8:7], |intrmProd[6:0]}; 
        EXP <= expAB + 1;
    end
    else begin
        normProd <= intrmProd[16:8];
        GRS <= {intrmProd[7:6], |intrmProd[5:0]}; 
        EXP <= expAB;
    end
end    
*/    

always @(*) begin
    invalid = inputIsInvalid;
    theNaN_del = theNaN;
    Rsel = {inputIsInvalid, anInputIsNaN, anInputIsInf || (intrmProd[17] ? &(expAB + 1) : &expAB)};
    sign = (AisZero || BisZero) ? 0 : (signA ^ signB);
    if (intrmProd[17]) begin
        normProd = intrmProd[17:9];
        GRS = {intrmProd[8:7], |intrmProd[6:0]}; 
        EXP = expAB + 1;
    end
    else begin
        normProd = intrmProd[16:8];
        GRS = {intrmProd[7:6], |intrmProd[5:0]}; 
        EXP = expAB;
    end
end    
                                                                                                        
endmodule                                                                                              
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                                                   
                            