#include "config.h"

#define	num_qubit 	3	
#define x_target	0

unsigned int create_oracle (COMPLEX_MATRIX* oracle, unsigned int num_total)
{
	unsigned int i, temp;
	oracle->cols = num_total; oracle->rows = num_total;
	oracle->t =(COMPLEX_NUM*) malloc ((oracle->rows*oracle->cols) * sizeof(COMPLEX_NUM)); if(oracle->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	//Preset all to 0
	for(i=0;i<(oracle->rows*oracle->cols);i++)
	{oracle->t[i].r = 0; oracle->t[i].i = 0;}
	
	for(i=0;i<oracle->rows;i++)
	{
		if((i>>1)==x_target)
		{
			temp = i^1;
			oracle->t[i*oracle->cols + temp].r = 1;
		}
		else
			oracle->t[i*oracle->cols + i].r = 1;
	}

	return 0;
}

unsigned int create_inverse_mean (COMPLEX_MATRIX* q_inverse_mean, unsigned int num_totalIn)	//-I + 2A
{
	unsigned int i,j;
	float M;
	q_inverse_mean->rows = num_totalIn; q_inverse_mean->cols = num_totalIn;
	q_inverse_mean->t =(COMPLEX_NUM*) malloc ((q_inverse_mean->rows * q_inverse_mean->cols) * sizeof(COMPLEX_NUM)); if(q_inverse_mean->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	//Let M = 2/(2^n):
	M = 2 / (float) num_totalIn;
	for(i=0;i<(q_inverse_mean->rows);i++)
		for(j=0;j<(q_inverse_mean->cols);j++)
		{
			if(i==j)
			{
				q_inverse_mean->t[(i*q_inverse_mean->cols) + j].r = -1+M; 	
				q_inverse_mean->t[(i*q_inverse_mean->cols) + j].i = 0;		//|-1+M	    M		M		M 	|
			}																//|	M     -1+M		M		M  	|
			else															//|	M		M     -1+M		M 	|
			{																//|	M		M		M     -1+M 	|
				q_inverse_mean->t[(i*q_inverse_mean->cols) + j].r = M; 
				q_inverse_mean->t[(i*q_inverse_mean->cols) + j].i = 0;
			}
		}		
	return 0;
}

int main()
{
	/**Variable Initialization**/
	unsigned int i, ite, num_totalIn, num_ite, num_total;
	COMPLEX_MATRIX input, output, target_in, ancilla_in, oracle, inverse_mean, identity, H, Hn, In_H, grover_op, ancilla_out, target_out; 
	target_in.cols = 0; target_in.rows = 0;	ancilla_in.cols = 0; ancilla_in.rows = 0; oracle.cols = 0; oracle.rows = 0; 
    identity.cols = 0; identity.rows = 0; H.cols = 0; H.rows = 0; Hn.cols = 0; Hn.rows = 0; inverse_mean.cols = 0; inverse_mean.rows = 0; 
    In_H.cols = 0; In_H.rows = 0; grover_op.cols = 0; grover_op.rows = 0; input.cols = 0; input.rows = 0; output.cols = 0; output.rows = 0; 
    ancilla_out.cols = 0; ancilla_out.rows = 0; target_out.cols = 0; target_out.rows = 0;
	
	printf("\t--Grover's Search Algorithm--\n");
	
	num_totalIn = pow(2,num_qubit);					//Number of combinations of binary string
	num_total = pow(2,num_qubit+1);					//Number of combinations of total number qubits (input qubit + 1 ancilla qubit)
	num_ite = floor (PI/4*sqrt(num_totalIn)); 		//Total number of search iteration required

	//Check validity 
	if(x_target>(num_totalIn-1) || num_qubit<2){printf("--Error: Number of qubit / target X out of range.--\n"); return 1;}
	printf("Number of Qubit: %d\tTotal of X: %d\tTarget X: %d\tNumber of Iteration: %d\n", num_qubit, num_total, x_target, num_ite);
	
	/******************************************/
	/*  		INITIALIZATION  	  		  */
	/******************************************/
	
	/**Initialize Input State Vector**/
	printf("\n~Input State Vector~\n");

	/**Separate target qubits & input qubits version**/
	target_in.cols = 1; target_in.rows = num_totalIn; ancilla_in.cols = 1; ancilla_in.rows = 2;
	target_in.t =(COMPLEX_NUM*) malloc ((target_in.rows) * sizeof(COMPLEX_NUM)); if(target_in.t==NULL){printf("--Error!: Malloc vector failed.--\n");return 1;}
	ancilla_in.t =(COMPLEX_NUM*) malloc ((ancilla_in.rows) * sizeof(COMPLEX_NUM)); if(ancilla_in.t==NULL){printf("--Error!: Malloc vector failed.--\n");return 1;}
	//For Grover's search algorithm, target qubits are set to 0, ancilla qubit (1-qubit) is set to 1, input state vector: |0...01>
	printf("\nTarget Qubits:\n");
	for(i=0;i<target_in.rows;i++)
	{target_in.t[i].r = 0; target_in.t[i].i = 0;}
	target_in.t[0].r = 1; 
	matrix_print_real(target_in);
	printf("\nAncilla Qubit:\n");
	ancilla_in.t[0].r = 0; ancilla_in.t[0].i = 0; ancilla_in.t[1].r = 1; ancilla_in.t[1].i = 0;
	matrix_print_real(ancilla_in);

	/******************************************/
	/*   Grover Operator Circuit Element	  */
	/******************************************/

	create_identity_matrix (&identity, 2);		
	quantum_hadamard (identity, &H);
	matrix_copy (H, &Hn);
	matrix_copy (identity, &In_H);
	//For the number of qubits
	for(i=0;i<(num_qubit-1);i++)
	{tensor_product (Hn, H, &Hn); tensor_product (In_H, identity, &In_H);}
//	printf("\n~H Unitary~\n");
//	matrix_print_real(H);
	printf("\n~Inversion About Mean Unitary~\n");
	create_inverse_mean (&inverse_mean, num_totalIn);	//-I + 2A
//	matrix_print_real(inverse_mean);
	/**Generate Hn, In_H, Oracle, -I+2A (X) I Unitaries in Grover Operator**/
	printf("\n~Hn Unitary~\n");
	matrix_print_real(Hn);
	printf("\n~In_H Unitary~\n");
	tensor_product (In_H, H, &In_H);
//	matrix_print_real(In_H);
	printf("\n~Oracle Circuit~\n");
	create_oracle (&oracle, num_total);	
//	matrix_print_real(oracle);

	/******************************************/
	/*  	Grover's Search Algorithm  		  */
	/******************************************/
	
	//Initialize output matrices -  Separate target qubits & ancilla qubit
	target_out.cols = 1; target_out.rows = num_totalIn;
	target_out.t =(COMPLEX_NUM*) malloc ((target_out.rows) * sizeof(COMPLEX_NUM)); if(target_out.t==NULL){printf("--Error!: Malloc vector failed.--\n");return 1;}
	ancilla_out.cols = 1; ancilla_out.rows = 2;
	ancilla_out.t =(COMPLEX_NUM*) malloc ((ancilla_out.rows) * sizeof(COMPLEX_NUM)); if(ancilla_out.t==NULL){printf("--Error!: Malloc vector failed.--\n");return 1;}
	ancilla_out.t[0].r = 1/sqrt(2); ancilla_out.t[0].i = 0; 
	ancilla_out.t[1].r = -1/sqrt(2); ancilla_out.t[1].i = 0;
	
	//HADAMARD APPLICATION - Equal probability
	printf("\n~Hadamard Application: Target Qubits~\n");
	matrix_mul (Hn, target_in, &target_out);
	matrix_print_real(target_out);
	
	/**ITERATION**/
	
	for(ite=0;ite<num_ite;ite++)
	{
		printf("\n\t\t-ITERATION %u-\n", ite+1);
	
		//Tensor Product of target_out & ancilla_in - Input to iteration circuit
		printf("\n~Iteration Circuit: Input Vector~\n");
		tensor_product (target_out, ancilla_in, &input);
		matrix_print_real(input);
		
		//HADAMARD APPLICATION - Ancilla qubit
		printf("\n~Hadamard Application: Ancilla Qubit~\n");
		matrix_mul (In_H, input, &output);
		matrix_print_real(output);
		
		//PHASE INVERSION: Oracle circuit
		printf("\n~Phase Inversion~\n");
		matrix_mul (oracle, output, &output);
		matrix_print_real(output);
		
		//SEPARATE TENSOR: Target qubits & ancilla qubit
		printf("\n~Separate Tensor: Target Qubits~\n");
		for(i=0;i<target_out.rows;i++)
		{target_out.t[i].r = output.t[i*2].r /  ancilla_out.t[0].r;}
		matrix_print_real(target_out);
		printf("\n~Separate Tensor: Ancilla Qubit~\n");
		matrix_print_real(ancilla_out);

		printf("\n~Inversion About Mean~\n");
		matrix_mul (inverse_mean, target_out, &target_out);
		matrix_print_real(target_out);
		
	}	
		
	matrix_free (&target_in); matrix_free (&ancilla_in); matrix_free (&identity); matrix_free (&H); matrix_free (&Hn); matrix_free (&In_H); 
    matrix_free (&inverse_mean); matrix_free (&grover_op); matrix_free (&input); matrix_free (&output); matrix_free (&ancilla_out); 
    matrix_free (&target_out);

	return 0;
}
