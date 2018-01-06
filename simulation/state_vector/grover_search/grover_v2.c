#include "config.h"

#define	num_qubit 	3				//number of search bit
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

unsigned int create_N_CNOT (COMPLEX_MATRIX* nCNOT, unsigned int num_totalIn)
{
	unsigned int i, temp, num; 
	num = pow(2,num_qubit-1);	//Based on the number of the control qubits
	
	nCNOT->cols = num_totalIn; nCNOT->rows = num_totalIn;
	nCNOT->t =(COMPLEX_NUM*) malloc ((nCNOT->rows*nCNOT->cols) * sizeof(COMPLEX_NUM)); if(nCNOT->t==NULL){printf("--Error!: Malloc gate matrix failed.--\n");return 1;}

	//Preset all to 0
	for(i=0;i<(nCNOT->rows*nCNOT->cols);i++)
	{nCNOT->t[i].r = 0; nCNOT->t[i].i = 0;}
	
	for(i=0;i<nCNOT->rows;i++)
	{
		if((i>>1)==(num-1))
		{
			temp = i^1;
			nCNOT->t[i*nCNOT->cols + temp].r = 1;
		}
		else
			nCNOT->t[i*nCNOT->cols + i].r = 1;
	}

	return 0;
}

int main()
{
	/**Variable Initialization**/
	unsigned int i, ite, num_totalIn, num_ite, num_total;
	COMPLEX_MATRIX oracle, input, identity, H, Hn, Hn_1, X, Xn, In_H, nCNOT, grover_op, output, ancilla_out, target_out, inverse_mean;
	oracle.cols = 0; oracle.rows = 0; input.cols = 0; input.rows = 0;  output.cols = 0; output.rows = 0; identity.cols = 0; identity.rows = 0; 
    H.cols = 0; H.rows = 0; Hn.cols = 0; Hn.rows = 0; Hn_1.cols = 0; Hn_1.rows = 0; X.cols = 0; X.rows = 0; Xn.cols = 0; Xn.rows = 0; 
	In_H.cols = 0; In_H.rows = 0; nCNOT.cols = 0; nCNOT.rows = 0; grover_op.cols = 0; grover_op.rows = 0; 
    ancilla_out.cols = 0; ancilla_out.rows = 0; target_out.cols = 0; target_out.rows = 0; inverse_mean.cols = 0; inverse_mean.rows = 0;
	
	printf("\t--Grover's Search Algorithm--\n");
	
	num_totalIn = pow(2,num_qubit);					//Number of combinations of binary string
	num_total = pow(2,num_qubit+1);					//Number of combinations of total number qubits (input qubit + 1 ancilla qubit)
//	float fp = (PI/4*sqrt(num_totalIn)); 
	num_ite = floor (PI/4*sqrt(num_totalIn)); 		//Total number of search iteration required	
	//Check validity 
	if(x_target>(num_totalIn-1) || num_qubit<2){printf("--Error: Number of qubit / target X out of range.--\n"); return 1;}
	printf("Number of Qubit: %d\tTotal of X: %d\tTarget X: %d\tNumber of Iteration: %d\n", num_qubit, num_total, x_target, num_ite);

	
	/******************************************/
	/*  		INITIALIZATION  	  		  */
	/******************************************/	
	
	/**Initialize Input State Vector**/
	//For Grover's search algorithm, input qubits are set to 0, ancilla qubit is set to 1,  |0...01>
	printf("\n~Input State Vector~\n");
	input.cols = 1; input.rows = num_total;
	input.t =(COMPLEX_NUM*) malloc ((input.rows) * sizeof(COMPLEX_NUM)); if(input.t==NULL){printf("--Error!: Malloc vector failed.--\n");return 1;}
	for(i=0;i<input.rows;i++)
	{input.t[i].r = 0; input.t[i].i = 0;}
	input.t[1].r = 1;
//	matrix_print_real(input);
	

	/******************************************/
	/*   Grover Operator Circuit Element 	  */
	/******************************************/
	
	/**Generate Hn, Hn (X) I, Xn (X) I, In (X) H (X) I Unitaries in Grover Operator**/
	create_identity_matrix (&identity, 2);		
	quantum_hadamard (identity, &H);
	quantum_not(identity, &X);
	matrix_copy (H, &Hn_1);
	matrix_copy (X, &Xn);
	matrix_copy (identity, &In_H);
	//For top num_qubit-2 qubits
	for(i=0;i<(num_qubit-2);i++)
	{
		tensor_product (Hn_1, H, &Hn_1);
		tensor_product (Xn, X, &Xn);	
		tensor_product (In_H, identity, &In_H);
	}
	//For the num_qubit-1 qubit
	tensor_product (Hn_1, H, &Hn_1);
	tensor_product (Xn, X, &Xn);
	tensor_product (In_H, H, &In_H);
	
	//Create N-qubit Hadamard Gate
	tensor_product (Hn_1, H, &Hn); 					
	printf("\n~Hn Unitary~\n");
	matrix_print_real(Hn);

	//Create oracle circuit
	printf("\n~Oracle Circuit~\n");
	create_oracle (&oracle, num_total);	
//	matrix_print_real(oracle);

	//Create (N-1)-qubit Hadamard Gate
	printf("\n~H(N-1) Unitary~\n");
//	matrix_print_real(Hn_1);
	
	//Create (N-1)-qubit NOT Gate
	printf("\n~X(N-1) Unitary~\n");
//	matrix_print_real(Xn);

	//Create I(N-2) (x) H Gate
	printf("\n~I(N-2) (x) H Unitary~\n");
//	matrix_print_real(In_H);
	
	//Create CNOT gate with (N-2) control qubits
	printf("\n~CNOT Unitary: (N-2) control qubit~\n");
	create_N_CNOT (&nCNOT, num_totalIn);
//	matrix_print_real(nCNOT);
	

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
	
	//HADAMARD APPLICATION 
	printf("\n~Hadamard Application: Target Qubits & Ancilla Qubit~\n");
	matrix_mul (Hn, input, &output);
	matrix_print_real(output);
	
	/**ITERATION**/
	
	for(ite=0;ite<num_ite;ite++)
	{
		printf("\n\t\t-ITERATION %u-\n", ite+1);
	
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
	
		//INVERSION ABOUT MEAN: Target qubits
		//Separate target qubits & ancilla qubit version
		printf("\n~Inversion About Mean: Target Qubits~\n");
		matrix_mul (Xn, Hn_1, &inverse_mean);
		matrix_mul (In_H, inverse_mean, &inverse_mean);
		matrix_mul (nCNOT, inverse_mean, &inverse_mean);
		matrix_mul (In_H, inverse_mean, &inverse_mean);
		matrix_mul (Xn, inverse_mean, &inverse_mean);
		matrix_mul (Hn_1, inverse_mean, &inverse_mean);
		//Apply inversion about mean circuit
		matrix_mul (inverse_mean, target_out, &target_out);
		matrix_print_real(target_out);
		
		//Combine target qubits & ancilla qubit
		tensor_product (target_out, ancilla_out, &output);
		printf("\n~Output State Vector~\n");
		matrix_print_real(output);
	}
	
	matrix_free (&oracle); matrix_free (&input); matrix_free (&output); matrix_free (&identity); matrix_free (&H); matrix_free (&Hn); 
    matrix_free (&Hn_1); matrix_free (&inverse_mean); matrix_free (&X); matrix_free (&Xn); matrix_free (&In_H); matrix_free (&nCNOT); 
    matrix_free (&grover_op); matrix_free (&ancilla_out); matrix_free (&target_out);

	return 0; 
}
