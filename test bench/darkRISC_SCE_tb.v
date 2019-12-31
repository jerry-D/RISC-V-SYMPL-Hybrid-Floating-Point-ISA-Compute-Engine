// darkRISC_SCE_tb.v
//
// Example testbench for SYMPL 64-Bit Universal Floating-point ISA Compute Engine and Fused Universal Neural Network (FuNN) eNNgine
//
// Author:  Jerry D. Harthcock
// Version:  1.21  November 28, 2019
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
// with said academic pursuit and under the supervision of said university or institution of higher education.        //                                                                           //            
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
   
//------------------- DESCRIPTION------------------------
//This Verilog test bench begins by first loading the RISC-V hybrid's program memory that the RISC-V executes 
//to orchestrate the processing that the SCEs are to perform.  Next, the test bench loads the RISC-V hybrid's 
//data memory with the program that the SCEs are to execute, followed by the test bench loading the data file 
//that SCE(0) is to process.  While SCE(1) does not include a FuNN operator, this same data file is simultaneously 
//pushed into it as well, mainly for the purpose of demonstrating simultaneous loads by the RISC-V hybrid.
//The program that is to be pushed into both SCEs simultaneously the RISC-V hybrid is a simple neural network 
//classification routine that SCE(0) executes to classify qty. (16) objects using SCE(0)'s on-board FuNN operator.  
//SCE(1) executes the same program, but since it has no FuNN operator with which to perform the required operations, 
//SCE(1) will eventually get trapped in a loop that attempts to read a result when there is none.
//Once the test bench pushes both the program and the data files into the SCEs, it releases RESET, allowing 
//the RISC-V hybrid core to run its program.  Once those things are accomplished, the test bench will sit and wait 
//for an indication that the RISC-V/SCE hybrid Compute Engine has completed processing, at which point the test bench 
//formats and writes the results to two files in the Vivado simulation directory for that project.  The two file 
//names are "assayPullForm.txt" and "randomNumbers.txt".  
//
//The file assayPullForm.txt" is a formatted, human-readable report showing the results of the neural network routine 
//that SCE(0) computed using its on-board FuNN operator.  The file "randomNumbers.txt" is an unformatted, is a 
//list of qty. (256) human-readable floating-point pseudo-random floating-point numbers in decimal character sequence 
//format that the RISC-V hybrid pulled directly from SCE(0)'s on-board PRNG. 
                                                                                                                    
`timescale 1ns/100ps

module darkRISC_SCE_tb();
                             
parameter byte  = 3'b000;      
parameter hword = 3'b001;      
parameter word  = 3'b010;
parameter dword = 3'b011;

integer r, file;
integer clk_high_time;               // high time for CPU clock  
integer j, k;
integer u, v, w, z, y;
integer progLen;

reg clk;
reg reset;

reg [63:0] ProgBuff64[16383:0];       //64-bit memory initially loaded with "<prog>.hex" file for SCE
reg [31:0] ProgBuff32[16383:0];       //32-bit memory initially loaded with "<prog>.hex" file for RISC-V
reg [1031:0] fatBuff_mem1032[255:0];  //1032-bit x 256 deep memory (1032 bits instead of 1024) because of LF character in the file
reg [5:0] objNo;
reg READY_q1;
wire done;

darkRISC_SCE DUT(
    .CLK  (clk  ),
    .RESET(reset),
    .READY_q1(READY_q1),
    .SCE_all_done (done)
    );    

   initial begin
        clk = 0;
        reset = 1;
        clk_high_time = 5;
        READY_q1 = 1;
                         

        // load the RISC_V program
        file = $fopen("risc_v_SCE_test.HEX", "rb");   
        r = $fread(ProgBuff32, file, 0);       
        $fclose(file); 
        @(posedge clk);
        progLen = ProgBuff32[1];                                                  
        k = 0;
        while(k<=progLen) begin
        #1
             DUT.progSRAM.twoportRAMA[k] = ProgBuff32[k];      
             k=k+1;
        end                                                                
        
        @(posedge clk);         
        
        // load the SCE program into RISC-V data memory so RISC-V can push it into SCE during initialization
        file = $fopen("FuNNtest2.hex", "rb");   
        r = $fread(ProgBuff64, file, 0);       
        $fclose(file); 
        @(posedge clk);
        progLen = ProgBuff64[1];                                                  
        k = 0;
        while(k<=progLen) begin
        #1
            DUT.dataSRAM_A.DataRAM_A.RAM[k] = ProgBuff64[k];      
            k=k+1;
        end                                                                
       
        @(posedge clk);         

         file = $fopen("objectsWeights.txt", "r");   //load 16 object X vectors and their corresponding layer0 weights RISC-V data memory
         r = $fread(fatBuff_mem1032, file);          //so that the RISC-V can push the data into SCE data memory for processing by SCE
         $fclose(file); 
          
         j = 'h200; 
         k = 0;                                
         while(k<32) begin  //qty (16) object vectors and qty (16) weight vectors (one for each object)
         #1   //this is a crude but effective way of eliminating the line feed after each input record
              DUT.dataSRAM_A.DataRAM_A.RAM[j+0]  = fatBuff_mem1032[k][1031:968];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+1]  = fatBuff_mem1032[k][ 967:904];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+2]  = fatBuff_mem1032[k][ 903:840];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+3]  = fatBuff_mem1032[k][ 839:776];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+4]  = fatBuff_mem1032[k][ 775:712];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+5]  = fatBuff_mem1032[k][ 711:648];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+6]  = fatBuff_mem1032[k][ 647:584];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+7]  = fatBuff_mem1032[k][ 583:520];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+8]  = fatBuff_mem1032[k][ 519:456];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+9]  = fatBuff_mem1032[k][ 455:392];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+10] = fatBuff_mem1032[k][ 391:328];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+11] = fatBuff_mem1032[k][ 327:264];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+12] = fatBuff_mem1032[k][ 263:200];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+13] = fatBuff_mem1032[k][ 199:136];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+14] = fatBuff_mem1032[k][ 135:72];      
              DUT.dataSRAM_A.DataRAM_A.RAM[j+15] = fatBuff_mem1032[k][  71: 8];      
              k=k+1;
              j=j+16;                                                   
         end                                                                
 
        
         @(posedge clk);
       // when RESET is active, SCE internal ForceBreak is automatically set to active to allow for SCE program memory loading by RISC-V
         @(posedge clk);
         #100 reset = 0;
         @(posedge clk);                                                  
 
  #100 wait(DUT.RISC_V_paddrs==32'h000002E4);  //wait for RISC-V PC to hit program address 0x000002E4
        
         @(posedge clk);
         #1
         //write the random human-readable floating-point decimal character representations to file, "randomNumbers.txt"
         r = 0;       
         file = $fopen("randomNumbers.txt", "wb");            
         while(r<256) begin
             $fwrite(file, "%s", DUT.dataSRAM_A.DataRAM_A.RAM[r+2308],"\n");
             r = r + 1;
         end 
         $fclose(file);
         @(posedge clk);
         #1
         
         //write each object X vector, its weight W vector, TanH (layer0), its Exponentials (layer1), Exponentials Summation (layer2), SoftMax/divides (layer3)
         //and HardMax (layer4) results formatted and in human-readable form to file, "assayPullForm.txt"
 
         file = $fopen("assayPullForm.txt", "wb"); //save results of 16-object by 16 input classification to file, "assayPullForm.txt", in human-readable form            

          v = 0;
          y=512;     //location in RISC-V data RAM of first object X vector
          w=768;     //location in RISC-V data RAM of first object W weight vector
          u=1025;    //location in RISC-V data RAM of first object computational results
          objNo=0;
          while(v<16) begin
          $fwrite(file, "Results for Object: %d", objNo, "\n");
          $fwrite(file, "  Input#:   XW15     XW14     XW13     XW12     XW11     XW10     XW9      XW8      XW7      XW6      XW5      XW4      XW3      XW2      XW1      XW0  ", "\n");
        
          $fwrite(file, "  Data X: ");    //get object X input vector
          z = 0;
          while(z<16) begin
             $fwrite(file, "%s",DUT.dataSRAM_A.DataRAM_A.RAM[y+z], " " ); 
             z = z+1;
          end
          y = y+16;   
          $fwrite(file, "\n");
         
          $fwrite(file, " Weights: ");    //get object X weights vector
          z = 0;
          while(z<16) begin
             $fwrite(file, "%s",DUT.dataSRAM_A.DataRAM_A.RAM[w+z], " " ); 
             z = z+1;   
          end
          w = w+16;   
          $fwrite(file, "\n");
         
          $fwrite(file, " TanH XW: ");    //get TanH(X*W) computations of X against each weight vector
          z = 16;
          while(z>0) begin
             $fwrite(file, "%s",DUT.dataSRAM_A.DataRAM_A.RAM[u+z-1], " " ); 
             z = z-1;   
          end
          u = u+16;   
          $fwrite(file, "\n");
         
          $fwrite(file, "     Exp: ");    //get exp(TanH(X*W)) computations of X against each weight vector
          z = 16;
          while(z>0) begin
             $fwrite(file, "%s",DUT.dataSRAM_A.DataRAM_A.RAM[u+z-1], " " ); 
             z = z-1;   
          end
          u = u+16;   
          $fwrite(file, "\n");
         
          $fwrite(file, "Sum(Exp): ");    //get sum(exp(TanH(X*W))) of all exponentials
          z = 0;
          while(z<16) begin
             $fwrite(file, "%s",DUT.dataSRAM_A.DataRAM_A.RAM[u+z], " " ); 
             z = z+1;   
          end
          u = u+16;   
          $fwrite(file, "\n");
         
          $fwrite(file, " SoftMax: ");    //get SoftMax
          z = 16;
          while(z>0) begin
             $fwrite(file, "%s",DUT.dataSRAM_A.DataRAM_A.RAM[u+z-1], " " ); 
             z = z-1;   
          end
          u = u+16;   
          $fwrite(file, "\n");
         
          $fwrite(file, " HardMax: ");    //get HardMax
          z = 16;
          while(z>0) begin
             $fwrite(file, "%s",DUT.dataSRAM_A.DataRAM_A.RAM[u+z-1], " " ); 
             z = z-1;   
          end
          u = u+16;   
          $fwrite(file, "\n");
             $fwrite(file, "\n");          
          v=v+1;
          objNo=objNo+1;
         end
         @(posedge clk);
         $fclose(file);
         @(posedge clk);
         
         #100 $finish;                  
   end 


always #clk_high_time clk = ~clk;

    
endmodule 

