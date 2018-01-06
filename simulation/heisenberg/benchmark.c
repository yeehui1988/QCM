#include "config.h"

//Print out gate sequence
void print_gate (BASIS_CIRCUIT c)
{
	unsigned int i;

	printf("\nGate Sequence: %hu gate(s)\n", c.size);
	for (i=0; i<c.size; i++)
	{
		if (c.type[i]==0)
			printf("-H_%hu-\t",c.pos[i*3]);
		else if (c.type[i]==1)
			printf("-P_%hu-\t",c.pos[i*3]);
		else if (c.type[i]==2)
			printf("-CNOT_%hu,%hu-\t",c.pos[i*3], c.pos[i*3+1]);
		else if (c.type[i]==3)
			printf("-MEASURE_%hu-\t",c.pos[i*3]);
		else if (c.type[i]==4)
		{
			printf("-CPHASE_%hu,%hu (%hu)-\t",c.pos[i*3], c.pos[i*3+1], c.pos[i*3+2]);
		}
		else if (c.type[i]==5)
		{
			printf("-TOFF_%hu,%hu,%hu-\t",c.pos[i*3], c.pos[i*3+1], c.pos[i*3+2]);
		}
	}
	printf("\n");	

	return;
}

//Print out stabilizer frame
void print_frame (SINGLE_FRAME frame, unsigned int num_qubit)
{
	unsigned int i,j;
	printf("Stabilizer Frame:\n");
	for(i=0;i<num_qubit;i++)		//For each row
	{	
		printf("|\t");
		for(j=0;j<num_qubit;j++)	//For each column
		{
			if(frame.literal[i][j] == 0)
				printf("I\t");
			else if(frame.literal[i][j] == 1)
				printf("Z\t");
			else if(frame.literal[i][j] == 2)
				printf("X\t");
			else
				printf("Y\t");
		}
		printf("|\n");
	}
	printf("\n");
	printf("Phase & Amplitude Vectors:\n");
	for(i=0;i<frame.pair_count;i++)
	{
		printf("Pair %u:\t (",i+1);
		for(j=0;j<num_qubit;j++)
		{
			if(frame.phase[i][j] == 0)
				printf("+");
			else
				printf("-");
		}
		printf(")\t%f + %fi\n",frame.amplitude[i].r,frame.amplitude[i].i);
	}
	printf("\n");
}

//Print out stabilizer frame
void print_frame_XZ (SINGLE_FRAME frame, unsigned int num_qubit)
{
	unsigned int i,j;
	printf("Stabilizer Frame:\n");
	for(i=0;i<num_qubit;i++)		//For each row
	{	
		printf("|\t");
		for(j=0;j<num_qubit;j++)	//For each column
		{
			if(frame.literal[i][j] == 0)
				printf("I\t");
			else if(frame.literal[i][j] == 1)
				printf("Z\t");
			else if(frame.literal[i][j] == 2)
				printf("X\t");
			else
				printf("Y\t");
		}
		printf("|\n");
	}
	printf("\n");
	printf("Phase Vectors:\n");
	for(i=0;i<frame.pair_count;i++)
	{
		printf("Pair %u:\t (",i+1);
		for(j=0;j<num_qubit;j++)
		{
			if(frame.phase[i][j] == 0)
				printf("+");
			else
				printf("-");
		}
		//printf(")\t%f + %fi\n",frame.amplitude[i].r,frame.amplitude[i].i);
	}
	printf("\n");
}

//Print out stabilizer frame
void print_frame2 (SINGLE_FRAME frame, unsigned int num_row, unsigned int num_qubit, unsigned int dimension)
{
	unsigned int i,j;
	printf("Stabilizer Frame:\n");
	for(i=0;i<num_row;i++)		    //For each row
	{	
		printf("|\t");
		for(j=0;j<num_qubit;j++)	//For each column
		{
			if(frame.literal[i][j] == 0)
				printf("I\t");
			else if(frame.literal[i][j] == 1)
				printf("Z\t");
			else if(frame.literal[i][j] == 2)
				printf("X\t");
			else
				printf("Y\t");
		}
		printf("|\n");
	}
	printf("\n");
	printf("Phase & Amplitude Vectors:\n");
	for(i=0;i<dimension;i++)
	{
		printf("Pair %u:\t (",i+1);
		for(j=0;j<num_row;j++)
		{
			if(frame.phase[i][j] == 0)
				printf("+");
			else
				printf("-");
		}
		printf(")\t%f + %fi\n",frame.amplitude[i].r,frame.amplitude[i].i);
	}
	printf("\n");
}

//Categorize based on the literal type of that row in stabilizer matrix
unsigned int pauli_row (unsigned short* stab_row, unsigned int num_qubit)
{
	unsigned int i, X_flag = 0, Y_flag = 0, Z_flag = 0;
	for (i=0;i<num_qubit;i++)
	{
		if (stab_row [i] == 1)
			Z_flag = 1;
		else if (stab_row [i] == 2)
			X_flag = 1;
		else if (stab_row [i] == 3)
			Y_flag = 1;
	}
	
	if (X_flag && Z_flag)
		return 3;
	else if (Y_flag && Z_flag)
		return 4;
	else if (Z_flag)
		return 0;
	else if (X_flag)
		return 1;
	else if (Y_flag)
		return 2;
	else 	//Not possible case
		return 100;
}

//Extract arbitrary nonzero basis amplitude from stabilizer frame
void extract_arbitrary (SINGLE_FRAME *frame,  unsigned int pair_index, int num_qubit, COMPLEX_NUM *basis_amplitude, unsigned int *basis_index)
{
	unsigned int i, j;	
	
	/***********************************************DECLARE & INITIALIZE P*****************************************************/
	//P: Array to hold X/I literals due to -ve phase Z literal row in Z-block  
	//Easiest way to determine an arbitrary nonzero amplitude is to extract it from P
	STABILIZER_ROW P;
	P.literal =(unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(P.literal==NULL){printf("--Error!: Malloc operator P failed.--\n");return;}
	P.phase = 0;
	//Initialize it to all I
	for(i=0;i<num_qubit;i++)
	{P.literal[i] = 0;}

	/***********************************************UPDATE P BASED ON Z-BLOCK*****************************************************/
	//Update the content of P based on -ve phase Z literal row in Z-block 
	unsigned int k = 0;
	for (i=0;i<num_qubit;i++)
	{
		if(pauli_row (frame->literal[i], num_qubit) == 0)	
		{
			for (j=0;j<num_qubit;j++)
			{
				if(frame->literal[i][j] == 1 && frame->phase[pair_index][i] == 1) //Literal Z & Row Phase -ve
				{
					P.literal[j] = 2; //Set jth literal of P to X - for first Z literal in that row only!!!
					break;			
				}
			}
		}
		else if(pauli_row (frame->literal[i], num_qubit) > 0) //Row that contains X or Y literal(s) - to determine the size of M'
		{k++;}
	}
	//printf("P: Updated");
	//print_row (P, num_qubit);

	/******************************************EXTRACT BASIS STATE IN BINARY FORM***********************************************/
	//Extract basis state in term of binary from P
	//P only contains X or I
	*basis_index = 0;
	for (j=0;j<num_qubit;j++)
		if(P.literal[j] == 2)	//jth literal is X-> set corresponding bit to 1
		 	*basis_index = *basis_index + pow(2, num_qubit-1-j);
	
	//The amplitude will only be +1 since P will not have negative sign and Y literal. DOUBLE-CHECK THIS!!! 	
	basis_amplitude -> r = 1; basis_amplitude -> i = 0;
	
	return;
}

//Decimal to binary (MSB ... LSB)
void dec_to_bin2 (unsigned int decimal, unsigned short* binary, unsigned int num_bit)
{
	unsigned int i;
	for(i=0;i<num_bit;i++)
		binary[i] = 0;

	i=0;
	while(decimal != 0)
	{
        binary[num_bit-1-i]= decimal % 2;
        decimal = decimal / 2;
		i++;
    }
}

//Convert binary (MSB ... LSB) to decimal
void bin_to_dec (unsigned short* binary, unsigned int num_bit, unsigned int *decimal)
{
	unsigned int i;

	*decimal=0;
	for (i=0;i<num_bit;i++)
	{
		if(binary[i]==1)
			*decimal += pow(2, num_bit-1-i);
	}

	return;
}

//Row multiplication where row2 = row1 * row2, imaginary factor is taken into consideration
void row_mult3 (STABILIZER_ROW stab_row1, STABILIZER_ROW* stab_row2, unsigned int num_qubit)
{
	unsigned int i, imag_factor;
	imag_factor = 0;

	//Literals update
	for(i=0; i<num_qubit; i++)
	{
		//For XY, YZ, ZX: i
		if((stab_row1.literal[i] == 2 && stab_row2->literal[i] == 3) || (stab_row1.literal[i] == 3 && stab_row2->literal[i] == 1) || (stab_row1.literal[i] == 1 && stab_row2->literal[i] == 2))
			imag_factor++;
		//For XZ, YX, ZY: -i
		else if ((stab_row1.literal[i] == 2 && stab_row2->literal[i] == 1) || (stab_row1.literal[i] == 3 && stab_row2->literal[i] == 2) || (stab_row1.literal[i] == 1 && stab_row2->literal[i] == 3)) 
			imag_factor = imag_factor + 3;
		stab_row2->literal[i] = stab_row1.literal[i] ^ stab_row2->literal[i];
	}
	
	//Phases update
	stab_row2->phase = stab_row1.phase ^ stab_row2->phase;
	imag_factor = imag_factor % 4;
	if(imag_factor == 2)
	{
		if (stab_row2->phase == 0)
			stab_row2->phase = 1;
		else
			stab_row2->phase = 0;
	}

	return;
}

//Extract the amplitude of a specific basis state from stabilizer frame - output could be zero or nonzero
void extract_specific (SINGLE_FRAME *frame, unsigned int pair_index, unsigned int num_qubit, unsigned int basis_index, COMPLEX_NUM *basis_amplitude)
{
	unsigned int i, j, k, l, decimal;	
	unsigned short *R;

	/***********************************************DECLARE & INITIALIZE R*****************************************************/
	//For extracting a specific basis state			
	R = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(R==NULL){printf("--Error!: Malloc binary counter failed.--\n");return;}
	dec_to_bin2 (basis_index, R, num_qubit);
	
	/***********************************************DECLARE & INITIALIZE P*****************************************************/
	//P: Array to hold X/I literals due to -ve phase Z literal row in Z-block  
	STABILIZER_ROW P;
	P.literal =(unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(P.literal==NULL){printf("--Error!: Malloc operator P failed.--\n");return;}
	P.phase = 0;
	//Initialize it to all I
	for(i=0;i<num_qubit;i++)
	{P.literal[i] = 0;}

	/***********************************************UPDATE P BASED ON Z-BLOCK*****************************************************/
	//Update the content of P based on -ve phase Z literal row in Z-block 
	k = 0;
	for (i=0;i<num_qubit;i++)
	{
		if(pauli_row (frame->literal[i], num_qubit) == 0)
		{
			for (j=0;j<num_qubit;j++)
			{
				if(frame->literal[i][j] == 1 && frame->phase[pair_index][i] == 1)	//Literal Z & Row Phase -ve
				{
					P.literal[j] = 2;	//Set jth literal of P to X - for first Z literal in that row only!!!
					break;			
				}
			}
		}
		else if(pauli_row (frame->literal[i], num_qubit) > 0)	//Row that contains X or Y literal(s) - to determine the size of M'
		{k++;}
	}

	/**********************************************EXTRACT A SPECIFIC BASIS STATE***********************************************/
	//R = basis_index XOR P^{MSB} for HW implementation
	//If else checking is more convenient for SW implementation
	for(i=0;i<num_qubit;i++)
	{
		if(P.literal[i] == 2)	//ith literal in P is X
		{
			//Toggle the particular bit in R
			if(R[i] == 1)
				R[i] = 0;
			else
				R[i] = 1;
		}
	}

	//Q: Array to store the resulted stabilizer row  
	STABILIZER_ROW Q;
	Q.literal =(unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(Q.literal==NULL){printf("--Error!: Malloc operator P failed.--\n");return;}
	Q.phase = 0;
	//Initialize it to the content of P
	for(i=0;i<num_qubit;i++)
	{Q.literal[i] = P.literal[i];}
	//Temporary row storage
	STABILIZER_ROW row_temp;

	for(i=0;i<num_qubit;i++)
	{
		if(R[i] == 1) //For each flag position in R
		{
			for(j=0;j<k;j++) //X-block
			{
				if(frame->literal[j][i] >= 2)           //ith literal in that stabilizer row is X or Y
				{
					//To make sure consistent data type is passed to the mult function
					row_temp.literal = frame->literal[j];
					row_temp.phase = frame->phase[pair_index][j];
					row_mult3 (row_temp, &Q, num_qubit); 
					//Update flag bit(s) in R accordingly
					for(l=0;l<num_qubit;l++)
					{
						if(frame->literal[j][l] >= 2)	//ith literal in that stabilizer row is X or Y
						{
							//Toggle the particular bit in R
							if(R[l] == 1)
								R[l] = 0;
							else
								R[l] = 1;
						}
					}
					break;
				}
			} 
		}
	}

	/******************************************EXTRACT BASIS STATE IN BINARY FORM***********************************************/	
	//Extract basis state in term of binary from Q
	unsigned int basis_temp = 0;
	COMPLEX_NUM imaginary;
	imaginary.r = 0; imaginary.i = 1;
	if (Q.phase == 0)
		basis_amplitude -> r = 1;
	else
		basis_amplitude -> r = -1;
	basis_amplitude -> i = 0;

	for (j=0;j<num_qubit;j++)
		if(Q.literal[j] == 2 || Q.literal[j] == 3)	//jth literal is X or Y -> set corresponding bit to 1
		{
		 	basis_temp = basis_temp + pow(2, num_qubit-1-j); 	
			if(Q.literal[j] == 3)			        //jth literal is Y -> set imaginary factor i
				complex_mul(*basis_amplitude, imaginary, &*basis_amplitude);
		}	

	//For the case of zero amplitude for that specific target basis state
	if (basis_temp != basis_index)
		{basis_amplitude -> r = 0; basis_amplitude -> i = 0;}
	
	return;
}

//Extract the amplitude of a basis state with specific qubit set to one or zero from stabilizer frame - output could be zero or nonzero
void extract_specific_qubit (SINGLE_FRAME *frame, unsigned int pair_index, unsigned int num_qubit, unsigned int *basis_index0, COMPLEX_NUM *basis_amplitude0, unsigned int *basis_index1, COMPLEX_NUM *basis_amplitude1, unsigned int qubit_pos)
{
	unsigned int i, j, k, l;	
	
	/***********************************************DECLARE & INITIALIZE P*****************************************************/
	//P: Array to hold X/I literals due to -ve phase Z literal row in Z-block  
	STABILIZER_ROW P;
	P.literal =(unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(P.literal==NULL){printf("--Error!: Malloc operator P failed.--\n");return;}
	P.phase = 0;
	//Initialize it to all I
	for(i=0;i<num_qubit;i++)
	{P.literal[i] = 0;}

	/***********************************************UPDATE P BASED ON Z-BLOCK*****************************************************/
	//Update the content of P based on -ve phase Z literal row in Z-block 
	k = 0;
	for (i=0;i<num_qubit;i++)
	{
		if(pauli_row (frame->literal[i], num_qubit) == 0)
		{
			for (j=0;j<num_qubit;j++)
			{
				if(frame->literal[i][j] == 1 && frame->phase[pair_index][i] == 1)	//Literal Z & Row Phase -ve
				{
					P.literal[j] = 2;	//Set jth literal of P to X - for first Z literal in that row only!!!
					break;			
				}
			}
		}
		//Row that contains X or Y literal(s) - to determine the size of M'
		else if(pauli_row (frame->literal[i], num_qubit) > 0)	
		{k++;}
	}

	//First of all, check if P fulfill the condition
	unsigned int target;
	*basis_index0 = 0; *basis_index1 = 0;
	if (P.literal[qubit_pos]==0) 		//Qubit value 0
	{
		basis_amplitude0 -> r = 1; basis_amplitude0 -> i = 0; 
		for (i=0;i<num_qubit;i++)
		{
			if(P.literal[i] == 2)
				*basis_index0 = *basis_index0 + pow(2, num_qubit-1-i); 
				
		}
		target = 1; //next target is with qubit position set to 1
	}
	else if (P.literal[qubit_pos]==2)	//Qubit value 1
	{
		basis_amplitude1 -> r = 1; basis_amplitude1 -> i = 0; 
		for (i=0;i<num_qubit;i++)
		{
			if(P.literal[i] == 2)
				*basis_index1 = *basis_index1 + pow(2, num_qubit-1-i); 
				
		}
		target = 0; //next target is with qubit position set to 0
	}

	//Q: Array to store the resulted stabilizer row  
	STABILIZER_ROW Q;
	Q.literal =(unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(Q.literal==NULL){printf("--Error!: Malloc operator P failed.--\n");return;}
	Q.phase = 0;
	//Initialize it to the content of P
	for(i=0;i<num_qubit;i++)
	{Q.literal[i] = P.literal[i];}
	//Temporary row storage
	STABILIZER_ROW row_temp;

	//Extract basis state of required qubit position and value
	//Literal X or Y toggle the bit in P, which leads to the required basis state
	for(i=0;i<num_qubit;i++) //For each row
	{
		if((frame->literal[i][qubit_pos] == 2) | (frame->literal[i][qubit_pos] == 3))
		{
			row_temp.literal = frame->literal[i];
			row_temp.phase = frame->phase[pair_index][i];
			row_mult3 (row_temp, &Q, num_qubit); 
			break;
		}
	}
	//printf("Q: Updated");
	//print_row (Q, num_qubit);

	//Extract basis state in term of binary from Q
	COMPLEX_NUM imaginary;
	imaginary.r = 0; imaginary.i = 1;

	if (target == 0)
	{
		if (Q.phase == 0)
			basis_amplitude0 -> r = 1;
		else
			basis_amplitude0 -> r = -1;
		basis_amplitude0 -> i = 0;
		for (j=0;j<num_qubit;j++)
			if(Q.literal[j] == 2 || Q.literal[j] == 3)	//jth literal is X or Y -> set corresponding bit to 1
			{
		 		*basis_index0 = *basis_index0 + pow(2, num_qubit-1-j); 	
				if(Q.literal[j] == 3)			        //jth literal is Y -> set imaginary factor i
					complex_mul(*basis_amplitude0, imaginary, &*basis_amplitude0);
			}	
	}
	else
	{
		if (Q.phase == 0)
			basis_amplitude1 -> r = 1;
		else
			basis_amplitude1 -> r = -1;
		basis_amplitude1 -> i = 0;
		for (j=0;j<num_qubit;j++)
			if(Q.literal[j] == 2 || Q.literal[j] == 3)  //jth literal is X or Y -> set corresponding bit to 1
			{
		 		*basis_index1 = *basis_index1 + pow(2, num_qubit-1-j); 	
				if(Q.literal[j] == 3)			        //jth literal is Y -> set imaginary factor i
					complex_mul(*basis_amplitude1, imaginary, &*basis_amplitude1);
			}	
	}
	
	return;
}

//Extract alpha for global phase maintenance: Hadamard gate
void get_alpha_H (SINGLE_FRAME *frame, unsigned int num_qubit, unsigned int pos_H, unsigned int *basis_index)
{
	//Two amplitudes to be extracted for the case of Hadamard gate
	COMPLEX_NUM basis_amplitude, basis_amplitude2, component, component2, element_H, alpha; 
	unsigned int i, basis_index2, k, temp, temp_const;
	element_H.r = 0.707107; element_H.i = 0;
	k = num_qubit - (pos_H + 1);
	temp_const = pow(2, k);
	
	for(i=0;i<frame->pair_count;i++)
	{
		//Step 1: Determine a nonzero amplitude basis state from input stabilizer frame
		//Extract arbitrary non-zero amplitude from stabilizer frame
		extract_arbitrary (&*frame, i, num_qubit, &basis_amplitude, &basis_index[i]);	

		//Step 2: Identify non-zero element(s) of a specific row based on the corresponding column in expanded gate matrix. 
		//Extract corresponding basis amplitudes of that row, ROW_x (if any). Obtain alpha.
		temp = basis_index[i] / temp_const;
		//Even: nonzero = a_{x} + a_{x + 2^k}	
		if(temp % 2 == 0) 	
		{
			basis_index2 = basis_index[i] + temp_const;
			extract_specific(&*frame, i, num_qubit, basis_index2, &basis_amplitude2);
			complex_mul(element_H, basis_amplitude, &component);   //a_{x}
			complex_mul(element_H, basis_amplitude2, &component2); //a_{x + 2^k}
			alpha.r = component.r + component2.r; alpha.i = component.i + component2.i;

			//Hadamard Gate: If resulted alpha is zero, basis index has to be updated to ensure that nonzero alpha is obtained
			if (alpha.r == 0 && alpha.i == 0)
			{
				basis_index[i] = basis_index[i] + temp_const; //Even: x = x + 2^k
				alpha.r = component.r - component2.r; alpha.i = component.i - component2.i;
			}
		}
		//Odd: nonzero = a_{x - 2^k} - a_{x}
		else			
		{
			basis_index2 = basis_index[i] - temp_const;
			extract_specific(&*frame, i, num_qubit, basis_index2, &basis_amplitude2);
			complex_mul(element_H, basis_amplitude, &component);   //a_{x}
			complex_mul(element_H, basis_amplitude2, &component2); //a_{x - 2^k}
			alpha.r = component2.r - component.r; alpha.i = component2.i - component.i;

			//Hadamard Gate: If resulted alpha is zero, basis index has to be updated to ensure that nonzero alpha is obtained
			if (alpha.r == 0 && alpha.i == 0)
			{
				basis_index[i] = basis_index[i] - temp_const; //Odd: x = x - 2^k
				alpha.r = component.r + component2.r; alpha.i = component.i + component2.i;
			}
		}

		//Update frame amplitude by merging alpha to it - update only valid after dividing by beta
		complex_mul(frame->amplitude[i], alpha, &frame->amplitude[i]);
		//printf("alpha[%u]: %f + %fi\n", i, alpha.r, alpha.i);	
	}

	return;
}

//Extract alpha for global phase maintenance: Phase gate
void get_alpha_P (SINGLE_FRAME *frame, unsigned int num_qubit, unsigned int pos_P, unsigned int *basis_index)
{
	//One amplitude to be extracted for the case of Phase gate
	COMPLEX_NUM basis_amplitude, basis_amplitude2, alpha; 
	unsigned int basis_index2, i, k, temp, temp_const;
	COMPLEX_NUM element_P;
	element_P.r = 0; element_P.i = 1;
	k = num_qubit - (pos_P + 1);
	temp_const = pow(2, k);	

	for(i=0;i<frame->pair_count;i++)
	{
		//Step 1: Determine a nonzero amplitude basis state from input stabilizer frame
		//Extract arbitrary non-zero amplitude from stabilizer frame
		extract_arbitrary (&*frame, i, num_qubit, &basis_amplitude, &basis_index[i]);

		//Step 2: Identify non-zero element(s) of a specific row based on the corresponding column in expanded gate matrix. 
		//Extract corresponding basis amplitudes of that row, ROW_x (if any). Obtain alpha.
		temp = basis_index[i] / temp_const;
		//Even: a_{x} 
		if(temp % 2 == 0) 	
		{alpha.r = basis_amplitude.r; alpha.i = basis_amplitude.i;}
		//Odd: a_{x} * imaginary i
		else			
		{complex_mul(element_P, basis_amplitude, &alpha);}

		//Update frame amplitude by merging alpha to it - update only valid after dividing by beta
		complex_mul(frame->amplitude[i], alpha, &frame->amplitude[i]);
		//printf("alpha[%u]: %f + %fi\n", i, alpha.r, alpha.i);
	}
	return;
}

//Extract alpha for global phase maintenance: CNOT gate
void get_alpha_CNOT (SINGLE_FRAME *frame, unsigned int num_qubit, unsigned int total_state, unsigned int pos_C, unsigned int pos_T, unsigned int *basis_index)
{
	COMPLEX_NUM alpha;
	unsigned int i;
	//Perform CNOT operation in simplified binary form
	unsigned short *binary;
	binary = (unsigned short*) malloc (num_qubit * sizeof(unsigned short)); if (binary==NULL) {printf("--Error!: Malloc binary failed.--\n");return;}
	
	for(i=0;i<frame->pair_count;i++)
	{
		//Step 1: Determine a nonzero amplitude basis state from input stabilizer frame
		extract_arbitrary (&*frame, i, num_qubit, &alpha, &basis_index[i]);
	
		//Step 2: Obtain corresponding updated position
		dec_to_bin2 (basis_index[i], binary, num_qubit);
		if(binary[pos_C] == 1) //If control qubit is 1
		{
			//Toggle target qubit
			if(binary[pos_T]==1) 
				binary[pos_T]=0; 
			else 
				binary[pos_T]=1;
		}
		bin_to_dec(binary, num_qubit, &basis_index[i]);

		//Update frame amplitude by merging alpha to it - update only valid after dividing by beta
		complex_mul(frame->amplitude[i], alpha, &frame->amplitude[i]);
		//printf("alpha[%u]: %f + %fi\n", i, alpha.r, alpha.i);
	}

	free(binary);
	return;
}

//Extract beta and update amplitude vector(s) for global phase maintenance
void get_beta (SINGLE_FRAME *frame, unsigned int num_qubit, unsigned int *basis_index)
{
	unsigned int i;
	COMPLEX_NUM beta;
	
	for(i=0;i<frame->pair_count;i++)
	{
		extract_specific(&*frame, i, num_qubit, basis_index[i], &beta);
		complex_div(frame->amplitude[i], beta, &frame->amplitude[i]);
		//printf("beta[%u]: %f + %fi\n", i, beta.r, beta.i);	
	}

	return;
}

//Conjugation-by-action for Hadamard gate
void conjugate_H (SINGLE_FRAME* frame, unsigned int num_qubit, unsigned int pos) 
{
	unsigned int i,j;
	for (i=0;i<num_qubit;i++)	//For each row
	{
		switch (frame->literal[i][pos]) //(stab_row[i].literal[pos])
		{
			case 1: //Input: Z; Output: X
				frame->literal[i][pos] = 2; break;
			case 2: //Input: X; Output: Z
				frame->literal[i][pos] = 1; break;
			case 3: //Input: Y; Output: -Y
				for (j=0;j<frame->pair_count;j++)
				{	
					if (frame->phase[j][i] == 0)
						frame->phase[j][i] = 1;
					else
						frame->phase[j][i] = 0;					
				}
				break;	
		}
	}	

	return;
}

//Conjugation-by-action for Phase gate
void conjugate_P (SINGLE_FRAME* frame, unsigned int num_qubit, unsigned int pos)
{
	unsigned int i,j;
	
	for (i=0;i<num_qubit;i++)	//For each row
	{
		switch (frame->literal[i][pos])
		{
			case 2: //Input: X; Output: Y
				frame->literal[i][pos] = 3; break;
			case 3: //Input: Y; Output: -X
				frame->literal[i][pos] = 2;
				for (j=0;j<frame->pair_count;j++)
				{	
					if (frame->phase[j][i] == 0)
						frame->phase[j][i] = 1;
					else
						frame->phase[j][i] = 0;					
				}
				break;		
		}
	}	

	return;
}

//Conjugation-by-action for CNOT gate (pos1: control qubit; pos2: target qubit)
void conjugate_CNOT  (SINGLE_FRAME* frame, unsigned int num_qubit, unsigned int pos1, unsigned int pos2)
{
	unsigned int i,j;
	
	for (i=0;i<num_qubit;i++)	//For each row
	{
		if (frame->literal[i][pos1] == 0) 
		{
			//case 0|0: //Input: II; Output: II
			if (frame->literal[i][pos2] == 1)	    //case (0&1): Input: IZ; Output: ZZ
				frame->literal[i][pos1] = 1;
			//case 0|2: //Input: IX; Output: IX
			else if (frame->literal[i][pos2] == 3)	//case (0&3): Input: IY; Output: ZY
				frame->literal[i][pos1] = 1;	
		}
		else if(frame->literal[i][pos1] == 1)	
		{
			//case 1|0: //Input: ZI; Output: ZI
			if (frame->literal[i][pos2] == 1)	    //case (1&1): Input: ZZ; Output: IZ
				frame->literal[i][pos1] = 0;	
			//case 1|2: //Input: ZX; Output: ZX
			else if (frame->literal[i][pos2] == 3) 	//case (1&3): Input: ZY; Output: IY
				frame->literal[i][pos1] = 0;					
		}
		else if(frame->literal[i][pos1] == 2)	
		{
			if (frame->literal[i][pos2] == 0) 	    //case (2&0): Input: XI; Output: XX
				frame->literal[i][pos2] = 2;
			else if (frame->literal[i][pos2] == 1) 	//case (2&1): Input: XZ; Output: -YY
			{
				frame->literal[i][pos1] = 3; frame->literal[i][pos2] = 3; 
				for (j=0;j<frame->pair_count;j++)
				{	
					if (frame->phase[j][i] == 0)
						frame->phase[j][i] = 1;
					else
						frame->phase[j][i] = 0;					
				} 
			}
			else if (frame->literal[i][pos2] == 2) 	//case (2&2): Input: XX; Output: XI
				frame->literal[i][pos2] = 0;
			else if (frame->literal[i][pos2] == 3) 	//case (2&3): Input: XY; Output: YZ
				{frame->literal[i][pos1] = 3; frame->literal[i][pos2] = 1;}
		}
		else if(frame->literal[i][pos1] == 3)	
		{
			if (frame->literal[i][pos2] == 0)	    //case (3&0): Input: YI; Output: YX
				frame->literal[i][pos2] = 2;
			else if (frame->literal[i][pos2] == 1) 	//case (3&1): Input: YZ; Output: XY
				{frame->literal[i][pos1] = 2; frame->literal[i][pos2] = 3;}
			else if (frame->literal[i][pos2] == 2) 	//case (3&2): Input: YX; Output: YI
				frame->literal[i][pos2] = 0;
			else if (frame->literal[i][pos2] == 3) 	//case (3&3): Input: YY; Output: -XZ
			{
				frame->literal[i][pos1] = 2; frame->literal[i][pos2] = 1; 
				for (j=0;j<frame->pair_count;j++)
				{	
					if (frame->phase[j][i] == 0)
						frame->phase[j][i] = 1;
					else
						frame->phase[j][i] = 0;					
				}
			}
		}	
	}	

	return;
}

//Row multiplication where row1 = row1 * row2, imaginary factor is taken into consideration
//Iterate over phase pair(s) with two input frames for canonical reduction and computational of basis states
void row_mult_frame (SINGLE_FRAME* frame1, unsigned int row_index1, SINGLE_FRAME frame2, unsigned int row_index2, unsigned int num_qubit)
{
	unsigned int i, imag_factor;
	imag_factor = 0;

	//Literals update
	for(i=0; i<num_qubit; i++)
	{
		//Identify imaginary factor
		//For XY, YZ, ZX: i
		if((frame1->literal[row_index1][i] == 2 && frame2.literal[row_index2][i] == 3) || (frame1->literal[row_index1][i] == 3 && frame2.literal[row_index2][i] == 1) || (frame1->literal[row_index1][i] == 1 && frame2.literal[row_index2][i] == 2))
			imag_factor++;
		 //For XZ, YX, ZY: -i
		else if((frame1->literal[row_index1][i] == 2 && frame2.literal[row_index2][i] == 1) || (frame1->literal[row_index1][i] == 3 && frame2.literal[row_index2][i] == 2) || (frame1->literal[row_index1][i] == 1 && frame2.literal[row_index2][i] == 3))			
			imag_factor = imag_factor + 3;
		//Update literal multiplication - XOR
		frame1->literal[row_index1][i] = frame1->literal[row_index1][i] ^ frame2.literal[row_index2][i];
	}
	
	//Phases update
	imag_factor = imag_factor % 4;
	for (i=0;i<frame1->pair_count;i++)
	{
		frame1->phase[i][row_index1] = frame1->phase[i][row_index1] ^ frame2.phase[i][row_index2];
		if(imag_factor == 2)
		{
			//Toggle the phase - change of sign
			if(frame1->phase[i][row_index1] == 0)
				frame1->phase[i][row_index1] = 1;
			else
				frame1->phase[i][row_index1] = 0;
		}
	}

	return;
}

//Arrange canonical row-reduced echelon form for stabilizer matrix  - Proposed Algorithm for HW implementation
void canonical_reduction (SINGLE_FRAME* frame, unsigned int num_qubit, unsigned int total_state)
{
	unsigned int i, j, k;

	/*************************************************X-block & Z-block Initialization**********************************************/
	SINGLE_FRAME X_block, Z_block;
	X_block.pair_count = frame->pair_count; Z_block.pair_count = frame->pair_count;

	//For phase storage
	X_block.phase = (unsigned short**) malloc ((total_state) * sizeof(unsigned short*)); if(X_block.phase==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	Z_block.phase = (unsigned short**) malloc ((total_state) * sizeof(unsigned short*)); if(Z_block.phase==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	for (i=0;i<frame->pair_count;i++)
	{	
		X_block.phase[i] = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(X_block.phase[i]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
		Z_block.phase[i] = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(Z_block.phase[i]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	}

	//For literal storage
	X_block.literal = (unsigned short**) malloc ((num_qubit) * sizeof(unsigned short*)); if(X_block.literal==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	Z_block.literal = (unsigned short**) malloc ((num_qubit) * sizeof(unsigned short*)); if(Z_block.literal==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	for (i=0;i<num_qubit;i++)
	{
		X_block.literal[i] = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(X_block.literal[i]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
		Z_block.literal[i] = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(Z_block.literal[i]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	}
	//For flag to indicate occupied row(s)
	unsigned short *X_flag, *Z_flag;
	X_flag = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(X_flag==NULL){printf("--Error!: Malloc stabilizer rows failed.--\n");return;}
	Z_flag = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(Z_flag==NULL){printf("--Error!: Malloc stabilizer rows failed.--\n");return;}
	for(i=0;i<num_qubit;i++)
	{X_flag[i] = 0; Z_flag[i] = 0;}


	/******************************First Round: Fit stabilizer rows according to its pivot position*****************************/
	//printf("\t\t--ROUND 1--\n");
	unsigned short fitted;
	for(i=0;i<num_qubit;i++) //For each row in stabilizer matrix
	{
		fitted = 0;
		for(j=0;j<num_qubit;j++)        //X-block
		{
			//If X or Y literal at pivot location
			if (frame->literal[i][j] == 2 || frame->literal[i][j] == 3)
			{
				//Pivot && !Occupy
				if (X_flag[j]==0)
				{
					for(k=0; k<num_qubit; k++)
						X_block.literal[j][k] = frame->literal[i][k]; 
					for(k=0; k<frame->pair_count; k++)
						X_block.phase[k][j] = frame->phase[k][i];
					X_flag[j]=1; 
					fitted=1; 
					break;
				}
				//Pivot && Occupy
				else
					{row_mult_frame (&*frame, i, X_block, j, num_qubit);}
			}
		}	
		if(fitted==0)
		{
			for(j=0;j<num_qubit;j++)    //Z-block
			{
				//Pivot && !Occupy - Z literal at pivot location
				if (frame->literal[i][j] == 1 && Z_flag[j] == 0)
				{
					for(k=0; k<num_qubit; k++)
						Z_block.literal[j][k] = frame->literal[i][k]; 
					for(k=0; k<frame->pair_count; k++)
						Z_block.phase[k][j] = frame->phase[k][i];	
					Z_flag[j]=1; 
					fitted=1; 
					break;
				}
				//Pivot && Occupy - Z or Y at pivot location
				else if ((frame->literal[i][j] == 1 || frame->literal[i][j] == 3) && Z_flag[j]==1)		
					{row_mult_frame (&*frame, i, Z_block, j, num_qubit);}	
			}
		}
		
	}


	/******************************Second Round: Minimize the number of X, Y, and Z literals in matrix*****************************/
	//printf("\t\t--ROUND 2--\n");
	//X-block
	for(i=0;i<num_qubit;i++)
	{
		if (X_flag[i] == 1)
		{
			for(j=i+1;j<num_qubit;j++) //The rest of X-block
			{
				//Minimize the X and Y literals
				if (X_flag[j] == 1 && X_block.literal[i][j] > 1) 
					{row_mult_frame (&X_block, i, X_block, j, num_qubit);}
			}
			for(j=0;j<num_qubit;j++) //Z-block
			{
				//Minimize the Z and Y literals
				if (Z_flag[j] == 1 && (X_block.literal[i][j]==1 || X_block.literal[i][j]==3))
					{row_mult_frame (&X_block, i, Z_block, j, num_qubit);}
			}	
		}
	}
	//Z-block
	for(i=0;i<num_qubit;i++)
	{
		if (Z_flag[i] == 1)
		{
			for(j=i+1;j<num_qubit;j++) //The rest of Z-block
			{
				//Minimize the Z and Y literals
				if (Z_flag[j] == 1 && (Z_block.literal[i][j]==1 || Z_block.literal[i][j]==3)) 
				{row_mult_frame (&Z_block, i, Z_block, j, num_qubit);}
			}
		}
	}

	//printf("\t--DEBUG Frame: X_block--\n");
	//print_frame_XZ(X_block,num_qubit);
	//printf("\t--DEBUG Frame: Z_block--\n");
	//print_frame_XZ(Z_block,num_qubit);

	/******************************Ensure correct output rows are copied back to the stabilizer matrix*****************************/
	unsigned int count = 0;
	for(i=0;i<num_qubit;i++)
	{
		if (X_flag[i] == 1)
		{
			for(j=0; j<num_qubit; j++)
				frame->literal[count][j] = X_block.literal[i][j];
			for(j=0; j<frame->pair_count; j++)
				frame->phase[j][count] = X_block.phase[j][i];
			count++;
		}
	}
	if(count < num_qubit)	//If valid row exists in Z-block
	{
		for(i=0;i<num_qubit;i++)
		{
			if (Z_flag[i] == 1)
			{
				for(j=0; j<num_qubit; j++)
					frame->literal[count][j] = Z_block.literal[i][j];
				for(j=0; j<frame->pair_count; j++)
					frame->phase[j][count] = Z_block.phase[j][i];				
				count++;
			}
		}
	}
/*
	//Free memory allocation
	for (i=0; i<total_state; i++)
		{free(X_block.phase[i]); free(Z_block.phase[i]);}
	free(X_block.phase); free(Z_block.phase); 
	for (i=0; i<num_qubit; i++)
		{free(X_block.literal[i]); free(Z_block.literal[i]);}
	free(X_block.literal); free(Z_block.literal); 
*/
	return;
}

//Row multiplication within a single frame where row1 = row1 * row2
void row_mult (SINGLE_FRAME* frame, unsigned int num_qubit, unsigned int row1, unsigned int row2)
{
	unsigned int i, imag_factor;
	imag_factor = 0;
	for(i=0; i<num_qubit; i++)
	{
		//For XY, YZ, ZX: i
		if((frame->literal[row1][i] == 2 && frame->literal[row2][i] == 3) || (frame->literal[row1][i] == 3 && frame->literal[row2][i] == 1) || (frame->literal[row1][i] == 1 && frame->literal[row2][i] == 2))
			imag_factor++;
		//For XZ, YX, ZY: -i
		else if ((frame->literal[row1][i] == 2 && frame->literal[row2][i] == 1) || (frame->literal[row1][i] == 3 && frame->literal[row2][i] == 2) || (frame->literal[row1][i] == 1 && frame->literal[row2][i] == 3)) 
			imag_factor = imag_factor + 3;
		frame->literal[row1][i] = frame->literal[row1][i] ^ frame->literal[row2][i];
	}	

	imag_factor = imag_factor % 4;
	for (i=0;i<frame->pair_count;i++)
	{
		frame->phase[i][row1] = frame->phase[i][row1] ^ frame->phase[i][row2];
		//According to Garcia, imaginary number should not exist in the resulted multiplication output		
		if(imag_factor == 2)
		{
			if (frame->phase[i][row1] == 0)
				frame->phase[i][row1] = 1;
			else
				frame->phase[i][row1] = 0;
		}
		
	}
	return;
}

//Facilitate measurement of stabilizer state superpositions and simulations of non-stabilizer gates using frames
void cofactor (SINGLE_FRAME* frame, unsigned int num_qubit, unsigned int total_state, unsigned int qubit_index)
{
	unsigned int i, j, l, anticommute, anticommute_row, Z_row, current_pair_count;
	COMPLEX_NUM amp_gen, factor;
	//Allocate for worst case
	//Somehow if allocate exact total_state location it causes segmentation fault, thus allocate 2 * total_state
	unsigned int *basis_index; unsigned int *basis_index2; unsigned int *swap_flag; 
	basis_index = (unsigned int*) malloc ((total_state*2) * sizeof(unsigned int)); if(basis_index==NULL){printf("--Error!: Malloc basis index failed.--\n");return;}
	basis_index2 = (unsigned int*) malloc ((total_state*2) * sizeof(unsigned int)); if(basis_index2==NULL){printf("--Error!: Malloc basis index failed.--\n");return;}
	swap_flag = (unsigned int*) malloc ((total_state*2) * sizeof(unsigned int)); if(swap_flag==NULL){printf("--Error!: Malloc flag failed.--\n");return;}

	COMPLEX_NUM *alpha;
	alpha = (COMPLEX_NUM*) malloc ((total_state) * sizeof(COMPLEX_NUM)); if(alpha==NULL){printf("--Error!: Malloc complex amplitudes failed.--\n");return;}
	//For oversize phase vector for randomized outcome case
	unsigned int found, unsigned_temp;	
	COMPLEX_NUM *alpha2;
	alpha2 = (COMPLEX_NUM*) malloc ((total_state) * sizeof(COMPLEX_NUM)); if(alpha2==NULL){printf("--Error!: Malloc complex amplitudes failed.--\n");return;}
	COMPLEX_NUM *amplitude_copy;
	amplitude_copy = (COMPLEX_NUM*) malloc ((total_state) * sizeof(COMPLEX_NUM)); if(amplitude_copy==NULL){printf("--Error!: Malloc complex amplitudes failed.--\n");return;}

	COMPLEX_NUM beta, factor2, complex_temp;
	

	/****************************************CHECK COMMUTATIVITY OF P = I_1 ... Z_k ... I_n****************************************/
	anticommute = 0;
	Z_row = 0;
	for (i=0;i<num_qubit;i++)	//frame[row][col]
	{	
		//Store row with Z literal on qubit_index position
		//Take the row with the lowest position in the stabilizer matrix???
		if (frame->literal[i][qubit_index] == 1)    
			Z_row = i;
		//Neither Z nor I on qubit index position - anticommute
		else if (frame->literal[i][qubit_index] > 1)	
			{anticommute = 1; anticommute_row = i; break;}
	}


	/***********************************************RANDOMIZED MEASUREMENT OUTCOME***********************************************/
	if (anticommute == 1)
	{
		/***************************************************MODIFIED VERSION****************************************************/
		for (i=0;i<frame->pair_count;i++)
		{
			//Obtain alpha to compute factor of cofactored amplitude
			//Retain the sequence of phase vector in the original list. 
			//Duplicated list with toggled phase at anticommuting row position is stored in list 2
			if (frame->phase[i][anticommute_row] == 0)
				extract_specific_qubit (&*frame, i, num_qubit, &basis_index[i], &alpha[i], &basis_index2[i], &alpha2[i], qubit_index);
			else
				extract_specific_qubit (&*frame, i, num_qubit, &basis_index2[i], &alpha2[i], &basis_index[i], &alpha[i], qubit_index);
			//Make a copy of original amplitudes
			amplitude_copy[i].r = 0; amplitude_copy[i].i = 0; swap_flag[i] = 0;
		}		

		//Step 1: If there is more than one anticommute rows, multiply it with the first one to make it commute
		for (i=anticommute_row+1; i<num_qubit; i++)
		{
			//If there is X or Y literal at qubit_index column which leads to anticommute
			//Multiply to make it commute: row1 = row1 * row2
			if (frame->literal[i][qubit_index] > 1)	
				{row_mult (&*frame, num_qubit, i, anticommute_row);}	
		}

		//Step 2: Set the anticommute row to P => Z literal at qubit_index position; I literal for the rest
		for (i=0;i<num_qubit;i++)
			{frame->literal[anticommute_row][i] = 0;}
		frame->literal[anticommute_row][qubit_index] = 1;

		//Step 3: Identify phase vector pair with opposite phase at anticommuting row and same phase for other rows for merging. 
		//	    : For other case, add new phase vector into list and copy over corresponding amplitude with alpha factor and basis index
		current_pair_count = frame->pair_count;
		for (i=0;i<current_pair_count-1;i++)
		{
			found = 0;
			if(swap_flag[i] == 0)
			{
				for (j=i+1;j<current_pair_count;j++)
				{
					for (l=0;l<num_qubit;l++)
					{
						if((frame->phase[i][l] == frame->phase[j][l]) && (l != anticommute_row) || (frame->phase[i][l] != frame->phase[j][l]) && (l == anticommute_row))
						{found = 1;}
						else
						{found = 0;break;}
					}
					if(found==1)
					{break;}
				}
				if(found == 1)
				{
					//Copy amplitude with alpha factor over to the match phase vector location for merging later
					amplitude_copy[i].r = frame->amplitude[j].r; amplitude_copy[i].i = frame->amplitude[j].i; 
					amplitude_copy[j].r = frame->amplitude[i].r; amplitude_copy[j].i = frame->amplitude[i].i; 
					complex_mul(amplitude_copy[i], alpha2[j], &amplitude_copy[i]);
					complex_mul(amplitude_copy[j], alpha2[i], &amplitude_copy[j]);

					//Update amplitude of original list with alpha factor & sum up the corresponding amplitude due to merging
					complex_mul(frame->amplitude[i], alpha[i], &frame->amplitude[i]);
					complex_mul(frame->amplitude[j], alpha[j], &frame->amplitude[j]);
					frame->amplitude[i].r += amplitude_copy[i].r; frame->amplitude[i].i += amplitude_copy[i].i; 
					frame->amplitude[j].r += amplitude_copy[j].r; frame->amplitude[j].i += amplitude_copy[j].i; 	
					swap_flag[i] = 1; swap_flag[j] = 1;
				}
				else //found == 0
				{
					//Add new phase vector into list 
					for (l=0;l<num_qubit;l++)
						{frame->phase[frame->pair_count][l] = frame->phase[i][l];}
					//Toggle phase at anticommuting row position
					if(frame->phase[i][anticommute_row] == 0)
						{frame->phase[frame->pair_count][anticommute_row] = 1;}
					else
						{frame->phase[frame->pair_count][anticommute_row] = 0;}	
					//Copy over amplitude with alpha factor and basis index
					//frame->amplitude[frame->pair_count].r = frame->amplitude[i].r; frame->amplitude[frame->pair_count].i = frame->amplitude[i].i; //not necessary
					complex_mul(frame->amplitude[i], alpha2[i], &frame->amplitude[frame->pair_count]);
					basis_index[frame->pair_count] = basis_index2[i];	 
					//Update amplitude of original list with alpha factor
					complex_mul(frame->amplitude[i], alpha[i], &frame->amplitude[i]); 	
					swap_flag[frame->pair_count] = 1;
					frame->pair_count++;
				}
			}
		} 
		//Add last phase vector of opposite phase in if flag==0 
		i=current_pair_count-1;
		if(swap_flag[i] == 0)
		{
			for (l=0;l<num_qubit;l++)
				{frame->phase[frame->pair_count][l] = frame->phase[i][l];}
			//Toggle phase at anticommuting row position
			if(frame->phase[i][anticommute_row] == 0)
				{frame->phase[frame->pair_count][anticommute_row] = 1;}
			else
				{frame->phase[frame->pair_count][anticommute_row] = 0;}	
			//Copy over amplitude with alpha factor and basis index
			//frame->amplitude[frame->pair_count].r = frame->amplitude[i].r; frame->amplitude[frame->pair_count].i = frame->amplitude[i].i; //not necessary
			complex_mul(frame->amplitude[i], alpha2[i], &frame->amplitude[frame->pair_count]);
			basis_index[frame->pair_count] = basis_index2[i];	 
			//Update amplitude of original list with alpha factor
			complex_mul(frame->amplitude[i], alpha[i], &frame->amplitude[i]); 	
			swap_flag[frame->pair_count] = 1;
			frame->pair_count++;
		}

		//Step 4: Perform canonical reduction to ensure correct basis amplitude extraction
		canonical_reduction (&*frame, num_qubit, total_state);

		//Step 5: Extract beta after cofactor operation & update amplitude
		for (i=0;i<frame->pair_count;i++)
		{
			extract_specific (&*frame, i, num_qubit, basis_index[i], &beta);
			complex_div(frame->amplitude[i], beta, &frame->amplitude[i]);
		}
	}
	/***********************************************DETERMINISTIC MEASUREMENT OUTCOME*******************************************/
	else
	{
		//printf("COFACTOR: Deterministic Measurement Outcome\n");
		//To ensure that row only contains one Z and others I
		for (i=0;i<num_qubit;i++)
		{
			if(i!=qubit_index && frame->literal[Z_row][i] != 0) 	
			{printf("--Error!: Contain non Z (qubit_index) or I (others) literals in Z row.--\n"); return;}	
		}
	}

	//free(basis_index); free(amp_ref); free(basis_index2);free(amp_ref2);free(amplitude2);

	return;
}

//Non-stabilizer gate application - Controlled phase-shift gate
void apply_controlled_phase (SINGLE_FRAME* frame, unsigned int num_qubit, unsigned int total_state, unsigned int c, unsigned int t, unsigned int phase_index)
{
	unsigned int i,j;
	float rad_angle; 
	COMPLEX_NUM phase_amplitude;
	rad_angle = 2*PI / pow(2,phase_index);
	phase_amplitude.r = cos(rad_angle); phase_amplitude.i = sin(rad_angle);

	//Step 1: Cofactor control qubit & perform canonical reduction	
	cofactor (&*frame, num_qubit, total_state, c);
	//print_frame(*frame,num_qubit);		
	
	//Step 2: Cofactor target qubit & perform canonical reduction
	cofactor (&*frame, num_qubit, total_state, t);
	//print_frame(*frame,num_qubit);

	//Step 3: Apply phase-shift operator of e^{i*alpha} if both control and target qubits are set
	unsigned int c_phase, t_phase, c_row, t_row;
	c_phase = 0; t_phase = 0;
	for (i=0;i<frame->pair_count;i++)
	{
		for (j=0;j<num_qubit;j++) //for each row
		{
			if(frame->literal[j][c] == 1)	//control qubit position is Z literal
			{c_phase = frame->phase[i][j]; c_row = j;}
			if(frame->literal[j][t] == 1)	//target qubit position is Z literal
			{t_phase = frame->phase[i][j]; t_row = j;}
		}
		if(c_phase == 1 && t_phase == 1)
			complex_mul (frame->amplitude[i], phase_amplitude, &frame->amplitude[i]);
		//These two cases should be mutually exclusive
		if (c_row == t_row)
		{printf("ERROR: C and T rows should be mutually exclusive!!\n");}	
	}
}

//Non-stabilizer gate application - Controlled phase-shift gate
void apply_toffoli (SINGLE_FRAME* frame, unsigned int num_qubit, unsigned int total_state, unsigned int c1, unsigned int c2, unsigned int t)
{
	unsigned int i,j;

	//Step 1: Cofactor control qubit1 & perform canonical reduction	
	cofactor (&*frame, num_qubit, total_state, c1);
	//printf("\t--Cofactored Frame: Qubit %u--\n", c1);
	//print_frame(*frame,num_qubit);

	//Step 2: Cofactor control qubit2 & perform canonical reduction	
	cofactor (&*frame, num_qubit, total_state, c2);	
	//printf("\t--Cofactored Frame: Qubit %u--\n", c2);
	//print_frame(*frame,num_qubit);

	//Step 3: Cofactor target qubit & perform canonical reduction	
	cofactor (&*frame, num_qubit, total_state, t);
	//printf("\t--Cofactored Frame: Qubit %u--\n", t);
	//print_frame(*frame,num_qubit);

	unsigned int c1_phase, c2_phase, t_phase, c1_row, c2_row, t_row;
	for (i=0;i<frame->pair_count;i++)
	{
		for (j=0;j<num_qubit;j++) //for each row
		{
			if(frame->literal[j][c1] == 1)	//control qubit position is Z literal
			{c1_phase = frame->phase[i][j]; c1_row = j;}
			if(frame->literal[j][c2] == 1)	//control qubit position is Z literal
			{c2_phase = frame->phase[i][j]; c2_row = j;}
			if(frame->literal[j][t] == 1)	//target qubit position is Z literal
			{t_phase = frame->phase[i][j]; t_row = j;}
		}	
		if(c1_phase == 1 && c2_phase == 1)
		{
			if(t_phase==1)
				{frame->phase[i][t_row] = 0;}
			else
				{frame->phase[i][t_row] = 1;}
		}
		if (c1_row == c2_row || c1_row == t_row || c2_row == t_row)
		{printf("ERROR: C1, C2 and T rows should be mutually exclusive!!\n");}
	}
			
	return;
}

//SWAP the output qubits for QFT 
void apply_swap (SINGLE_FRAME* frame, unsigned int num_qubit)
{
	unsigned int i,j;

	STABILIZER_ROW temp;
	temp.literal =(unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(temp.literal==NULL){printf("--Error!: Malloc operator temp failed.--\n");return;}

	for (i=0;i<num_qubit;i++) //For each row
	{
		for (j=0;j<num_qubit;j++) //For each column
		{temp.literal[num_qubit-1-j] = frame->literal[i][j];}
		for (j=0;j<num_qubit;j++) //For each column
		{frame->literal[i][j] = temp.literal[j];}
	}
}

//Row multiplication where row1 = row1 * row2, imaginary factor is taken into consideration
//Iterate over phase pair(s) with two input frames for canonical reduction and computational of basis states
void row_mult_QP (SINGLE_FRAME Q, SINGLE_FRAME P, unsigned int Q_state_index, unsigned int pair_index, SINGLE_FRAME* U, unsigned int num_qubit)
{
	unsigned int i, imag_factor;
	imag_factor = 0;

	//Literals update
	for(i=0; i<num_qubit; i++)
	{
		//Identify imaginary factor
		//For XY, YZ, ZX: i
		if((Q.literal[Q_state_index][i] == 2 && P.literal[pair_index][i] == 3) || (Q.literal[Q_state_index][i] == 3 && P.literal[pair_index][i] == 1) || (Q.literal[Q_state_index][i] == 1 && P.literal[pair_index][i] == 2))
			imag_factor++;
		 //For XZ, YX, ZY: -i
		else if((Q.literal[Q_state_index][i] == 2 && P.literal[pair_index][i] == 1) || (Q.literal[Q_state_index][i] == 3 && P.literal[pair_index][i] == 2) || (Q.literal[Q_state_index][i] == 1 && P.literal[pair_index][i] == 3))			
			imag_factor = imag_factor + 3;
		//Update literal multiplication - XOR
		U->literal[0][i] = Q.literal[Q_state_index][i] ^ P.literal[pair_index][i];
	}

	//Phases update
	imag_factor = imag_factor % 4;
	U->phase[0][0] = Q.phase[pair_index][Q_state_index] ^ P.phase[pair_index][0];
	if(imag_factor == 2)
	{
		//Toggle the phase - change of sign
		if(U->phase[0][0] == 0)
			U->phase[0][0] = 1;
		else
			U->phase[0][0] = 0;
	}
	return;
}

//Modify this to print out basis amplitudes of stabilizer frame with multiple vector pairs
void basis_amplitude (SINGLE_FRAME frame, unsigned int num_qubit, unsigned int total_state)
{
	/*********************************************VARIABLE INITIALIZATION********************************************/
	unsigned int i, j, k, l;

	/************************************MEMORY INITIALIZATION FOR COMPUTATION OF BASIS STATE************************************/
	//Move to main function to avoid random malloc issue
	//Initialization of P, always positve phase and initialize to I
	//P.phase[pair_count][0]
	//P.literal[pair_count][num_qubit]
	SINGLE_FRAME P;	
	P.phase = (unsigned short**) malloc ((total_state) * sizeof(unsigned short*)); if(P.phase==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}		        //pair_count
	for (i=0;i<total_state;i++)
	{P.phase[i] = (unsigned short*) malloc ((1) * sizeof(unsigned short)); if(P.phase[i]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}} 			        //1
	for (i=0;i<total_state;i++)
	{P.phase[i][0] = 0;}	
	P.literal = (unsigned short**) malloc ((total_state) * sizeof(unsigned short*)); if(P.literal==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}		//pair_count
	for (i=0;i<total_state;i++)
	{P.literal[i] = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(P.literal[i]==NULL){printf("--This Error!: Malloc stabilizer frame failed.--\n");return;}} 	//num_qubit
	for (i=0;i<total_state;i++)
		for (j=0;j<num_qubit;j++)
		{P.literal[i][j]=0;}
	P.amplitude = (COMPLEX_NUM*) malloc ((1) * sizeof(COMPLEX_NUM)); if(P.amplitude==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	P.amplitude[0].r = 0; P.amplitude[0].i = 0;

	//Frame to store Q <- GROUP (M')
	//Q.phase[pair_count][Q_state]
	//Q.literal[Q_state][num_qubit]
	SINGLE_FRAME Q;
	Q.phase = (unsigned short**) malloc ((total_state) * sizeof(unsigned short*)); if(Q.phase==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}		        //pair_count
	for (i=0;i<total_state;i++)
	{Q.phase[i] = (unsigned short*) malloc ((total_state) * sizeof(unsigned short)); if(Q.phase[i]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}}	//Q_state
	Q.literal = (unsigned short**) malloc ((total_state) * sizeof(unsigned short*)); if(Q.literal==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}		//Q_state
	for (i=0;i<total_state;i++)
	{Q.literal[i] = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(Q.literal[i]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}}	//num_qubit
	//Initialization
	for(i=0; i<total_state; i++)
		for(j=0; j<total_state; j++)
			Q.phase[i][j] = 0;

	//Frame to store QxP
	//U.phase[0][0]
	//U.literal[0][num_qubit]
	SINGLE_FRAME U;
	U.pair_count = 1;
	U.phase = (unsigned short**) malloc ((1) * sizeof(unsigned short*)); if(U.phase==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}		
	U.phase[0] = (unsigned short*) malloc ((1) * sizeof(unsigned short)); if(U.phase[0]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	U.literal = (unsigned short**) malloc ((1) * sizeof(unsigned short*)); if(U.literal==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	U.literal[0] = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(U.literal[0]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return;}
	P.pair_count = frame.pair_count;
	Q.pair_count = frame.pair_count;

	//STEP1: Extraction of P (one row multiply by pair_count) based on Z-block with -ve phase row
	k = 0;	//count number of rows in X-block
	for (i=0;i<num_qubit;i++)
	{	
		if (pauli_row (frame.literal[i], num_qubit) == 0)       //Contain literal(s) Z or I only
		{
			for (j=0;j<frame.pair_count;j++)
			{
				if (frame.phase[j][i] == 1)
				{
					for (l=0;l<num_qubit;l++)
					{
						if (frame.literal[i][l] == 1)
						{
							//Set jth literal to X, for first -Z literal in the row only!
							P.literal[j][l] = 2; 
							break;
						}
					}
				}
			}
		}
		else if(pauli_row (frame.literal[i], num_qubit) > 0)	//Contain literal(s) X or Y 
		{k++;}
	}
	
	unsigned int Q_state = pow(2, k);	//number of nonzero basis amplitudes

	//STEP 2: Q <- Group (M') where M' is X-block in M
	unsigned short *binary;	
	binary = (unsigned short*) malloc ((k) * sizeof(unsigned short)); if(binary==NULL){printf("--Error!: Malloc binary counter failed.--\n");return;}
	
	for(i=0; i<Q_state; i++)
	{		
		for(j=0; j<num_qubit; j++)
			Q.literal[i][j] = 0;
		dec_to_bin2 (i, binary, k);
		for(j=0; j<k; j++)
		{
			if(binary[j] == 1)
				row_mult_frame (&Q, i, frame, j,  num_qubit);
		}
	}

	//STEP 3: Obtain nonzero basis states
	//Iterate through the vector pairs
	unsigned int b;
	COMPLEX_NUM s, imaginary;
	imaginary.r = 0; imaginary.i = 1;

	//Vector to store extracted basis states
	COMPLEX_MATRIX a;
	a.rows = total_state; a.cols = 1;
	a.t =(COMPLEX_NUM*) malloc ((a.rows*a.cols) * sizeof(COMPLEX_NUM)); if(a.t==NULL){printf("--Error!: Malloc matrix failed.--\n");return;}
	for (i=0;i<total_state;i++)
	{a.t[i].r = 0; a.t[i].i = 0;}

	for(i=0; i<frame.pair_count; i++)
	{
		for (j=0;j<Q_state;j++)
		{
			U.phase[0][0] = 0;
			for (l=0;l<num_qubit;l++)
				U.literal[0][l] = 0;
			//Ui = Qi x P
			row_mult_QP (Q, P, j, i, &U, num_qubit);
			//Mapped the phase sign over
			if (U.phase[0][0] == 0) 
				{s.r = 1; s.i = 0;}	
			else			
				{s.r = -1; s.i = 0;}
			//Set basis state and amplitudes
			b=0;
			for (l=0;l<num_qubit;l++)
			{
				if(U.literal[0][l] == 2 || U.literal[0][l] == 3) //lth literal is X or Y
				{
					b = b + pow(2, num_qubit-1-l);
					if(U.literal[0][l] == 3) //jth literal is Y
						complex_mul(s, imaginary, &s);
				}

			}
			complex_mul(s, frame.amplitude[i], &s);	
			a.t[b].r += s.r;// /(float)(sqrt(pow(2,Q_state))); 
			a.t[b].i += s.i;// /(float)(sqrt(pow(2,Q_state))); 
		}	
	}

	printf("Basis Amplitudes:\n");
	matrix_print(a);
	printf("\n");
/*
	//Free memory allocation
	for (i=0; i<total_state; i++)
		{free(Q.phase[i]); free(Q.literal[i]); free(P.phase[i]); free(P.literal[i]);}
	free(Q.phase); free(Q.literal); free(P.phase); free(P.literal);
*/
}

int main ()
{ 

	unsigned int i, j, total_state, num_qubit;

	/****************************************READ RANDOM SEQUENCE STABILIZER GATES FROM FILE*************************************/
	char temp_c;
	BASIS_CIRCUIT gate_sequence;

	//Read gate sequence information
	FILE *INPUT;
	INPUT = fopen("benchmark_mod.txt", "r");
	fscanf(INPUT, "%u", &num_qubit);
	fscanf(INPUT, "%u", &gate_sequence.size);

	total_state = pow (2, num_qubit);

	printf("\t\t--Benchmark Circuit: %u-qubit--\n", num_qubit);
	printf("Number of Qubit: %u \tNumber of Gate: %u\n", num_qubit, gate_sequence.size);	
	total_state = pow (2, num_qubit);	
	//Memory allocation for storing gate sequence
	gate_sequence.type = (unsigned short*) malloc ((gate_sequence.size) * sizeof(unsigned short)); if(gate_sequence.type==NULL){printf("--Error!: Malloc gate sequence failed.--\n");return 1;}
	gate_sequence.pos = (unsigned short*) malloc ((gate_sequence.size*3) * sizeof(unsigned short)); if(gate_sequence.pos==NULL){printf("--Error!: Malloc gate sequence failed.--\n");return 1;}
	//Read & store gate sequence in quantum circuit
	for (i=0;i<gate_sequence.size;i++)
	{
		//To discard redudant input such as next line from file
		do
		{fscanf(INPUT, "%c", &temp_c);}while((temp_c=='\r')||(temp_c=='\n'));
		//Gate Type(s): 0 = Hadamard; 1 = Phase; 2 = CNOT; 3 = CPHASE (Controlled-Z)
		//For this case consider 3 = Measurement gate as stabilizer-based simulation support this 4 types of gates
		if ((temp_c=='h')||(temp_c=='H'))
		{
			gate_sequence.type[i] = 0;
			fscanf(INPUT, "%hu", &gate_sequence.pos[3*i]); gate_sequence.pos[3*i+1]=0; gate_sequence.pos[3*i+2]=0;
			//printf("sequence %u: Gate H\tPosition %hu\n", i,gate_sequence.pos[2*i]);
		}
		else if ((temp_c=='p')||(temp_c=='P'))
		{
			gate_sequence.type[i] = 1;
			fscanf(INPUT, "%hu", &gate_sequence.pos[3*i]); gate_sequence.pos[3*i+1]=0; gate_sequence.pos[3*i+2]=0;
			//printf("sequence %u: Gate P\tPosition %hu\n", i,gate_sequence.pos[2*i]);
		}
		else if ((temp_c=='c')||(temp_c=='C'))
		{
			gate_sequence.type[i] = 2;
			fscanf(INPUT, "%hu", &gate_sequence.pos[3*i]); fscanf(INPUT, "%hu", &gate_sequence.pos[3*i+1]);
			gate_sequence.pos[3*i+2]=0;
			//printf("sequence %u: Gate CNOT\tPosition %hu %hu\n", i,gate_sequence.pos[2*i],gate_sequence.pos[2*i+1]);
		}
		else if ((temp_c=='m')||(temp_c=='M'))
		{
			gate_sequence.type[i] = 3;
			fscanf(INPUT, "%hu", &gate_sequence.pos[3*i]); gate_sequence.pos[3*i+1]=0; gate_sequence.pos[3*i+2]=0;
			//printf("sequence %u: Gate M\tPosition %hu\n", i,gate_sequence.pos[2*i]);
		}
		else if ((temp_c=='s')||(temp_c=='S'))
		{
			gate_sequence.type[i] = 4;
			fscanf(INPUT, "%hu", &gate_sequence.pos[3*i]); fscanf(INPUT, "%hu", &gate_sequence.pos[3*i+1]); 
			fscanf(INPUT, "%hu", &gate_sequence.pos[3*i+2]); 
			//printf("sequence %u: Gate Phase Shift\tPosition %hu, %hu (%hu)\n", i,gate_sequence.pos[3*i], gate_sequence.pos[3*i+1],gate_sequence.pos[3*i+2]);
		}
		else if ((temp_c=='t')||(temp_c=='T'))
		{
			gate_sequence.type[i] = 5;
			fscanf(INPUT, "%hu", &gate_sequence.pos[3*i]); fscanf(INPUT, "%hu", &gate_sequence.pos[3*i+1]); 
			fscanf(INPUT, "%hu", &gate_sequence.pos[3*i+2]); 
			//printf("sequence %u: Gate Toffoli\tPosition %hu, %hu, %hu\n", i,gate_sequence.pos[3*i], gate_sequence.pos[3*i+1],gate_sequence.pos[3*i+2]);
		}	 
	}
	fclose(INPUT);
	print_gate(gate_sequence);

	/************************************INITIALIZATION OF INPUT STABILIZER FRAME TO BASIS STATE************************************/

	SINGLE_FRAME frame;
	frame.pair_count = 0;
	//Phase and amplitude vector pairs: max 2^n pairs for n-qubit system
	frame.amplitude = (COMPLEX_NUM*) malloc ((total_state) * sizeof(COMPLEX_NUM)); if(frame.amplitude==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return 1;}	
	frame.phase = (unsigned short**) malloc ((total_state) * sizeof(unsigned short*)); if(frame.phase==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return 1;}
	for (i=0;i<total_state;i++)
	{
		frame.phase[i] = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(frame.phase[i]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return 1;}
	}
	//Stabilizer Matrix: n-by-n literals
	frame.literal = (unsigned short**) malloc ((num_qubit) * sizeof(unsigned short*)); if(frame.literal==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return 1;}
	for (i=0;i<num_qubit;i++)
	{
		frame.literal[i] = (unsigned short*) malloc ((num_qubit) * sizeof(unsigned short)); if(frame.literal[i]==NULL){printf("--Error!: Malloc stabilizer frame failed.--\n");return 1;}
	}

	//Content initialization: Basis state 0(x)n
	for (i=0;i<num_qubit;i++)
		for (j=0;j<num_qubit;j++)
		{
			if(i==j) //Set diagonal literals to Z others to I
				frame.literal[i][j] = 1;
			else
				frame.literal[i][j] = 0;
		}
	for (i=0;i<num_qubit;i++)	
		frame.phase[frame.pair_count][i] = 0;// 1;

    //Hard-set initial state to arbitrary intended basis state
///*
	frame.phase[frame.pair_count][0] = 1;
	frame.phase[frame.pair_count][1] = 1;
	frame.phase[frame.pair_count][2] = 1;
	frame.phase[frame.pair_count][3] = 1;
	frame.phase[frame.pair_count][4] = 1;
//*/

	frame.amplitude[frame.pair_count].r = 1; frame.amplitude[frame.pair_count].i = 0;
	frame.pair_count++;  

	printf("\n\t--Initial Frame--\n");
	print_frame(frame,num_qubit);
	//basis_amplitude (frame, num_qubit, total_state);


	/******************************************************APPLY GATE SEQUENCE******************************************************/
	unsigned int *basis_index;
	basis_index = (unsigned int*) malloc ((total_state) * sizeof(unsigned int)); if(basis_index==NULL){printf("--Error!: Malloc gate sequence failed.--\n");return 1;}

	for (i=0;i<gate_sequence.size;i++)
	{
		if (gate_sequence.type[i]==0)		//Hadamard Gate
		{
			//printf("\n\t\t--Gate Sequence %u: Apply Hadamard Gate on Qubit %u--\n", i, gate_sequence.pos[3*i]);
			//Step 1: Obtain alpha - for global phase maintenance
			get_alpha_H (&frame, num_qubit, gate_sequence.pos[3*i], basis_index);
			//Step 2: Conjugation-by-action
			conjugate_H (&frame, num_qubit, gate_sequence.pos[3*i]);
			//Step 3: Canonical form reduction
			canonical_reduction (&frame, num_qubit, total_state);
			//Step 4: Obtain beta & update amplitude vector(s) - for global phase maintenance
			get_beta (&frame, num_qubit, basis_index);			
		}
		else if (gate_sequence.type[i]==1)	//Phase Gate
		{
			//printf("\n\t\t--Gate Sequence %u: Apply Phase Gate on Qubit %u--\n", i, gate_sequence.pos[3*i]);
			//Step 1: Obtain alpha
			get_alpha_P (&frame, num_qubit, gate_sequence.pos[3*i], basis_index);
			//Step 2: Conjugation-by-action
			conjugate_P (&frame, num_qubit, gate_sequence.pos[3*i]);
			//Step 3: Canonical form reduction
			canonical_reduction (&frame, num_qubit, total_state);
			//Step 4: Obtain beta & update amplitude vector(s) - for global phase maintenance
			get_beta (&frame, num_qubit, basis_index);
		}
		else if (gate_sequence.type[i]==2)	//CNOT Gate
		{
			//printf("\n\t\t--Gate Sequence %u: Apply CNOT Gate on Control Qubit %u; Target Qubit %u--\n", i, gate_sequence.pos[3*i], gate_sequence.pos[3*i+1]);
			//Step 1: Obtain alpha
			get_alpha_CNOT (&frame, num_qubit, total_state, gate_sequence.pos[3*i], gate_sequence.pos[3*i+1], basis_index);
			//Step 2: Conjugation-by-action
			conjugate_CNOT (&frame, num_qubit, gate_sequence.pos[3*i], gate_sequence.pos[3*i+1]);
			//Step 3: Canonical form reduction
			canonical_reduction (&frame, num_qubit, total_state);
			//Step 4: Obtain beta & update amplitude vector(s) - for global phase maintenance
			get_beta (&frame, num_qubit, basis_index);
		}
		else if (gate_sequence.type[i]==3)	//Measurement Gate: To-be constructed
		{
			//printf("\n\t\t--Gate Sequence %u: Apply Measurement on Qubit %u--\n", i, gate_sequence.pos[3*i]);
		}
		else if (gate_sequence.type[i]==4)	//Controlled Phase-Shift Gate
		{
			//printf("\n\t\t--Gate Sequence %u: Apply Controlled Phase-Shift on Qubit %u, %u (%u)--\n", i, gate_sequence.pos[3*i], gate_sequence.pos[3*i+1], gate_sequence.pos[3*i+2]);
			apply_controlled_phase (&frame, num_qubit, total_state, gate_sequence.pos[3*i], gate_sequence.pos[3*i+1], gate_sequence.pos[3*i+2]);
		}
		else if (gate_sequence.type[i]==5)	//Toffoli Gate
		{
			//printf("\n\t\t--Gate Sequence %u: Apply Toffoli on Qubit %u, %u, %u--\n", i, gate_sequence.pos[3*i], gate_sequence.pos[3*i+1], gate_sequence.pos[3*i+2]);
			apply_toffoli (&frame, num_qubit, total_state, gate_sequence.pos[3*i], gate_sequence.pos[3*i+1], gate_sequence.pos[3*i+2]);
		}

		printf("\t--Intermediate Frame--\n");
		print_frame(frame,num_qubit);
        //Extract basis states from stabilizer frames Heisenberg representation and print out the content
		//basis_amplitude (frame, num_qubit, total_state);
	}

	return 0;
}
