// cnvTHC.v
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

module cnvTHC(
    nybleIn,
    charOut
    );
    
input [3:0] nybleIn;
output [7:0] charOut;

parameter _0_ = 8'h30;
parameter _1_ = 8'h31;
parameter _2_ = 8'h32;
parameter _3_ = 8'h33;
parameter _4_ = 8'h34;
parameter _5_ = 8'h35;
parameter _6_ = 8'h36;
parameter _7_ = 8'h37;
parameter _8_ = 8'h38;
parameter _9_ = 8'h39;
parameter _A_ = 8'b0100_0001;
parameter _B_ = 8'b0100_0010;
parameter _C_ = 8'b0100_0011;
parameter _D_ = 8'b0100_0100;
parameter _E_ = 8'b0100_0101;
parameter _F_ = 8'b0100_0110;

reg [7:0] charOut;

always @(*)
    casex(nybleIn)
        4'h0 : charOut = _0_;    
        4'h1 : charOut = _1_;    
        4'h2 : charOut = _2_;    
        4'h3 : charOut = _3_;    
        4'h4 : charOut = _4_;    
        4'h5 : charOut = _5_;    
        4'h6 : charOut = _6_;    
        4'h7 : charOut = _7_;    
        4'h8 : charOut = _8_;    
        4'h9 : charOut = _9_;    
        4'hA : charOut = _A_;    
        4'hB : charOut = _B_;    
        4'hC : charOut = _C_;    
        4'hD : charOut = _D_;    
        4'hE : charOut = _E_;
        4'hF : charOut = _F_;
    default : charOut = _F_;    
    endcase    

endmodule
