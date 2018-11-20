#include <stdio.h>
#include <math.h>

#define shift_bit 22
#define num_data 32

int main()
{
	float float_point1, float_point2, convert;
	int fixed_point1, fixed_point2;
	unsigned int i;

	printf("\t~Floating Point to Fixed Point Conversion~\n");
	convert = pow(2,shift_bit); 	//Fixed point shift precision	

	printf("\n-Read input from file-\n");
	FILE *input1; FILE *input2;
	FILE *output1; FILE *output2;
	input1=fopen("float_r_C.txt","r");	output1=fopen("fixed_r_C.txt","w");	
    input2=fopen("float_i_C.txt","r");	output2=fopen("fixed_i_C.txt","w");	

	for(i=0;i<num_data;i++)
	{
		fscanf(input1,"%f",&float_point1);
		fixed_point1 = (int) (float_point1*convert);
		fprintf(output1,"%x\n",fixed_point1);

        fscanf(input2,"%f",&float_point2);
		fixed_point2 = (int) (float_point2*convert);
		fprintf(output2,"%x\n",fixed_point2);
	}

	fclose(input1); fclose(input2);
	fclose(output1); fclose(output2);

	printf("-Done outputs written to file-\n");
	return 0;
}
