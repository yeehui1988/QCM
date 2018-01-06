#** Details of the implemented quantum circuit modelling and algorithms using Heisenberg representation can be found in our paper (Improved quantum circuit modelling based on Heisenberg representation).

#Modelling of benchmark circuits based on Heisenberg representations.
benchmark: 
	gcc benchmark.c -o benchmark -lm

#Modelling of qft circuit with randomized input stabilizer states based on Heisenberg representations.
qft: 
	gcc qft_stabilizer.c -o qft_stabilizer -lm

all:
	gcc benchmark.c -o benchmark -lm
	gcc qft_stabilizer.c -o qft_stabilizer -lm
