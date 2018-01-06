#** Theoretical background of Grover's search algorithm and descriptions of its corresponding models can be found in our paper (An FPGA-Based Quantum Computing Emulation Framework Based on Serial-Parallel Architecture).

#Version 1      : Quantum circuit model for Grover's search given black box functions of phase inversion and inversion about mean are available.
#Version 2      : Quantum circuit model for Grover's search constructed using oracle, Hadamard, and NOT gates.
#Version Math   : Grover's search model based on mathematical operations of phase inversion and inversion about mean.

v1:
	gcc grover_v1.c -o grover_v1 -lm 

v2:
	gcc grover_v2.c -o grover_v2 -lm  

math:
	gcc grover_math.c -o grover_math -lm

all:
	gcc grover_v1.c -o grover_v1 -lm
	gcc grover_v2.c -o grover_v2 -lm
	gcc grover_math.c -o grover_math -lm    
