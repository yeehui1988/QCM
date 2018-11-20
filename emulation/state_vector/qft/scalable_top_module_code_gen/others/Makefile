#** Conversion between floating point and fixed point to facilite testbench verification of generated FPGA emulation hardware.

#fix2float : Convert from fixed point to floating point. Verify outputs generated from testbench.
#float2fix : Convert from floating point to fixed point. Convert to fixed point inputs to be fed to testbench.

fix2float:
	gcc fix2float.c -o fix2float -lm 

float2fix:
	gcc float2fix.c -o float2fix -lm  

all:
	gcc fix2float.c -o fix2float -lm 
	gcc float2fix.c -o float2fix -lm   
