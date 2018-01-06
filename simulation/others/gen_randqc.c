#include <stdio.h>
#include <stdlib.h>
#include <time.h>

unsigned int getrandom(unsigned int n)
{
	unsigned int r = (RAND_MAX*rand() + rand()) % n;
	r = (r + n) % n;
	return r;
}

int main ()//(int argc, char **argv)

{
	unsigned int n = 4;		// number of qubits
	unsigned int T = 10;	// number of gates
	double m = 0.0f;	    // measurement

	double c = 1.0f;	// portion of gates that are CNOT
	double h = 1.0f;	// Hadamard
	double p = 1.0f;	// phase
//	double m = 1.0f;	// measurement
	double sum;
	double r;
	unsigned int a;
	unsigned int b;
	unsigned int i;

	srand(time(0));

	sum = c+h+p+m;
	c /= sum;
	h /= sum;
	p /= sum;
	m /= sum;

	printf("Randomly-generated Clifford group quantum circuit");
	printf("\nn=%u qubits, T=%u gates", n, T);
	printf("\nInstruction mix: %.2lf%% CNOT, %.2lf%% Hadamard, %.2lf%% Phase, %.2lf%% Measurement\n",
			100.0f*c, 100.0f*h, 100.0f*p, 100.0f*m);

	FILE *output;
	output=fopen("randqc.txt","w");
    fprintf(output,"%u\t%u\n", n, T);
	for (i = 0; i < T; i++)
	{
		r = (double)rand()/RAND_MAX;
		a = getrandom(n);
		b = a;
		while (b==a)
				b = getrandom(n);
		if (r < c) 
		{
			printf("\nc %u %u", a, b); 
			fprintf(output,"c\t%u\t%u\n", a, b);
		}
		else if (r < c+h) 
		{
			printf("\nh %u", a); 
			fprintf(output,"h\t%u\n", a);
		}
		else if (r < c+h+p) 
		{
			printf("\np %u", a);
			fprintf(output,"p\t%u\n", a);
		}
		else 
		{
			printf("\nm %u", a);
			fprintf(output,"m\t%u\n", a);
		}
	}
	printf("\n");
	fclose(output);
	
	return 0; 

}
