#include <stdio.h>
#include <math.h>

#define shift_bit 22
#define num_data 32

int main()
{
	float float_point, convert;
	int fixed_point;
	unsigned int i;

	printf("\t~Fixed Point to Floating Point Conversion~\n");
	convert = pow(2,shift_bit); 	//Fixed point shift precision

	printf("\n-Read input from file-\n");
	FILE *input1; FILE *input2;
	FILE *output1; FILE *output2;
	input1=fopen("fixed_r_SV.txt","r");	input2=fopen("fixed_i_SV.txt","r");
	output1=fopen("float_r_SV.txt","w"); output2=fopen("float_i_SV.txt","w");
	
	for(i=0;i<num_data;i++)
	{
		fscanf(input1,"%x",&fixed_point);
		float_point = fixed_point / convert;
		fprintf(output1,"%f\n",float_point);
		fscanf(input2,"%x",&fixed_point);
		float_point = fixed_point / convert;
		fprintf(output2,"%f\n",float_point);
	}

	fclose(input1);	fclose(input2);
	fclose(output1); fclose(output2);

	printf("-Done outputs written to file-\n");

	return 0;
}
