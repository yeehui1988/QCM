#include "config.h"

#define	num_qubit 	3	
#define x_target	0

int main()
{
	printf("\t--Grover's Search Algorithm: Mathematical Model--\n");
	
	unsigned int i, ite, num_total, num_ite;
	float equal_prob, mean;
	
	num_total = pow(2,num_qubit);
	num_ite = floor (PI/4*sqrt(num_total)); 		//Total number of search iteration required

	//Check validity 
	if(x_target>(num_total-1) || num_qubit<2){printf("--Error: Number of qubit / target X out of range.--\n"); return 1;}
	printf("Number of Qubit: %d\tTarget X: %d\tNumber of Iteration: %d\n", num_qubit, x_target, num_ite);
	
	COMPLEX_MATRIX state_vector;
	state_vector.cols = 1; state_vector.rows = num_total;
	state_vector.t =(COMPLEX_NUM*) malloc ((state_vector.rows) * sizeof(COMPLEX_NUM)); if(state_vector.t==NULL){printf("--Error!: Malloc vector failed.--\n");return 1;}
	
	//INITIALIZATION - All set to zeros
	printf("\n~Input State Vector~\n");
	for(i=0;i<state_vector.rows;i++)
	{state_vector.t[i].r = 0; state_vector.t[i].i = 0;}
	matrix_print_real (state_vector);
		
	//HADAMARD APPLICATION - Equal probability
	printf("\n~Hadamard Application: Equal Probability~\n");
	equal_prob = 1 / sqrt(num_total);
	for(i=0;i<state_vector.rows;i++)
		state_vector.t[i].r = equal_prob;
	matrix_print_real (state_vector);
	
	for(ite=0;ite<num_ite;ite++)
	{
		printf("\n\t\t-ITERATION %u-\n", ite+1);
		
		//PHASE INVERSION: By position
		printf("\n~Phase Inversion~\n");
		state_vector.t[x_target].r = -state_vector.t[x_target].r;
		matrix_print_real (state_vector);
		
		printf("\n~Inversion About Mean~\n");
		mean = 0;
		for(i=0;i<state_vector.rows;i++)
			mean += state_vector.t[i].r;	//sum

		mean /= (float) num_total;			//average

		for(i=0;i<state_vector.rows;i++)	//inversion about mean: -v + 2a
			state_vector.t[i].r = -state_vector.t[i].r + 2*mean;	
		matrix_print_real (state_vector); 
	}	
	
	matrix_free (&state_vector); 

	return 0;
}
