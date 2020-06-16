![](https://github.com/jerry-D/RISC-V-SYMPL-Hybrid-Floating-Point-ISA-Compute-Engine/blob/master/RISC_V_SYMPL_logo_med.png)
### New hybrid ISA genetically splices the instruction pipeline of a RISC-V to the instruction pipelines of one or more SYMPL Compute Engines, giving you the best of both worlds in a single package.

(December 30, 2019) They said it couldn't be done.  Written entirely in Verilog RTL, this new RISC-V/SYMPL Compute Engine genetically splices the instruction pipeline of a RISC-V RV32I or RV64I to the instruction pipelines of one or more SYMPL universal floating-point Compute Engines to create a very powerful hybrid floating-point ISA.

In the process the RISC-V wound up with capabilities it never had before and was most likely never anticipated, like, for example, a REPEAT counter, which, when not = 1, freezes the PC and employs auto-post modification of registers used as indirect pointers into memory, with ability to move entire vectors of floating-point data having elements from 1 to 128 bytes in length with a single hybrid instruction.  The new RISC-V/SYMPL hybrid ISA now has the ability to compute directly with floating-point decimal character sequence representation without first having to explicitly convert them to binary floating-point format beforehand.  A RISC-V implementer can now honestly make the claim that their design is fully IEEE 754-2008 compliant in hardware, in that this hybrid ISA has the hardware infrastructure in place to do so.

Designed for easy implementation in Xilinx Kintex Ultra and Ultra+ brand FPGAS, in this repository you will find all the Verilog RTL source files needed to start creating your own custom RISC-V/SYMPL hybrid ISA Compute Engine designs free of charge.

![](https://github.com/jerry-D/RISC-V-SYMPL-Hybrid-Floating-Point-ISA-Compute-Engine/blob/master/RISC_V_SCE_Hybrid.png)

At this repository you will also find several Preliminary Information documentation to help you familiarize yourself with and use this new hybrid floating-point ISA.  For starters, here is an 11-page primer on the new hybrid instruction set:

https://github.com/jerry-D/RISC-V-SYMPL-Hybrid-Floating-Point-ISA-Compute-Engine/blob/master/RISC_V_SCE.pdf

Here is a .pdf information sheet on the SYMPL Fused Neural Network (FuNN) eNNgine employed by the new hybrid ISA:

https://github.com/jerry-D/RISC-V-SYMPL-Hybrid-Floating-Point-ISA-Compute-Engine/blob/master/SYMPL_neuron16b_large.pdf

Here is a detailed description of the SYMPL floating-point compute engine itself:

https://github.com/jerry-D/RISC-V-SYMPL-Hybrid-Floating-Point-ISA-Compute-Engine/blob/master/UFP_ISA.pdf

## Simulating in Xilinx Vivado IDE
All the Verilog RTL source files that you will need are located in the “RTL", "ASM", "test bench", and "input" folders at this repository.  The top level module is “darkRISC_SCE.v”.  It is suggested that when creating your project in Vivado the first time, you select the Xilinx Kintex Ultra+ xcku5p-ffvd-900-3-e as your target device.  

After creating your project in Vivado, you will need to click on the “Compile Order” tab, click on “darkRISC_SCE.v” and slide it up to the top.  “SYMPL_COMPUTE_ENGINE_AI.v” should be slid immediately under “darkRISC_SCE.v” because most of the “tick” defines are in the “SYMPL_COMPUTE_ENGINE_AI.v” module.  Under the "Sources" tab, at the bottom of the panel, click "hierarchy", then right-click on "darkRISC_SCE.v" and select "Set as Top" if not already in bold font.  

The next step is to pull the “darkRISC_SCE_tb.v” test bench file into Vivado as your stimulus.  Then slide down to "Simulation Sources">"sim_1" and do the same thing for the test bench, "darkRISC_SCE_tb.v" as you did for "darkRISC_SCE.v", setting it as "top" in the simulation sources. 

Once you've done that, click on “Run Simulation”.  After doing that, you will notice that the simulation fails.  This is because the simulation requires the “FuNNtest2.HEX” program for the RISC-V/SYMPL hybrid Compute Engine to execute. So to fix that, paste the “FuNNtest2.HEX” file into the simulation working directory at:  C:\projectName\projectName .sim\sim_1\behav\xsim  .  “FuNNtest2.HEX” and assembly language source and object listing can be found in the “ASM” folder.  

Next, the demonstration simulation, which is an object classification routine, requires a file of 16-input X object vectors and corresponding weight W vectors.  The name of this human-readable file is “objectsWeights.txt” and can be found in the “input” folder.  This file comprises qty. (16) 16-element vectors of human-readable decimal character sequences with token exponents.  The first record/vector is X0 object, the second record is X1 object, and so on, until you get to X15 object.  After that is W0 weight vector for object X0, and the one after that is W1 vector for object X1, and so on.  This “objectsWeights.txt” file must be pasted in the same working directory that you placed the “FuNNtest2.HEX” file.  Once you've done that, click on the “Run Simulation” button again to launch the simulation.

When the simulation is complete, you should be able to find two new .txt files in the same working directory as a result of the simulation.  One file is “randomNumbers.txt” and the other is “assayPullForm.txt”.  “randomNumbers” is just a table of qty. (16) vectors of H=7 human-readable decimal-character floating-point representation generated by the SYMPL Compute Engine's human-readable floating-point pseudo-random number generator (PRNG) as a result of the RISC-V hybrid pulling them directly out of the SYMPL Compute Engine. “ assayPullForm.txt” is a formatted listing of all the values in all the layers that resulted from program execution.  Because these outputs are decimal character representations, you can load them into your favorite text editor or spread sheet.  Exact copies of these outputs can be found in the “input” and “output” folder, so you can compare your results with what is expected.

For information on what the demonstration does, refer to the assembly language object listing in the “ASM” folder and the “darkRISC_SCE_tb.v” test bench source code.

## Packages Omitted
You may quickly notice that the IEEE754-2008 floating-point operators, integer and logical operators, and XCUs have been omitted from this publication.  I omitted them mainly because the FuNN eNNgine does not require them and I didn't want those evaluating the underlying ISA architecture to get lost in the details.  However, if you would like to evaluate them, please let me know and I'll see what I can do to get you set up with that.  Also, if you need assistance gene-splicing your own version of the RISC-V to the SYMPL floating-point Compute Engine, please don't hesitate to contact me.

## Credits
The RISC-V portion of this hybrid ISA design is a modified version of a RV32I design that can be found a the following repository at GitHub:
https://github.com/darklife/darkriscv
As a word of caution, I eventually discovered that the original design at the above link employs asynchronous SRAM for data memory and my design employs synchronous SRAMS.  Thus, the read timing for accessing data RAM is off by one clock.  To work around this problem, simply use two consecutive LW (load word) instructions instead of one.  This is also true for the hybrid XLOAD instructions, but does not apply to the hybrid XPULL or any other hybrid instructions.

When I can find the time, I will most likely design my own rendition of the RISC-V (RV64I) and publish it here or elsewhere. 

Enjoy!
