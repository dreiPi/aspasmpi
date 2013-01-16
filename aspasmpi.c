#include <stdio.h>
#include <sys/time.h>

#define M_PI		3.14159265358979323846
#define E_0			8.85418781762e-12
#define E_GUMMI		3.0
#define E_PAPIER	5.0

void calc(float* data1, float* data2, float* result1, float* result2, int length);
void calc_c(float* data1, float* data2, float* result1, float* result2, int length);

int main(int argc, char **argv) {
	struct timeval start, ende;
	gettimeofday(&start,0);
	
	//calc(...)

	gettimeofday(&ende, 0);
	printf("time needed: %d usec \n", (ende.tv_sec - start.tv_sec)*1000000+ende.tv_usec-start.tv_usec);
	return 0;

	//TODO Rahmenprogramm
}

void calc_c (float* data1, float* data2, float* result1, float* result2, int length) {
	float r1, r2, faktor,bruch, k1, k2;
	for(int i = 0; i < length; i++) {
		r1 = data1[i];
		r2 = data2[i];
		faktor = 4 * M_PI * E_0;
		bruch = (r2 * r1) / (r2 - r1);
		k1 = faktor * bruch * E_GUMMI;
		k2 = faktor * bruch * E_PAPIER;
		result1[i] = k1;
		result2[i] = k2;
	}
}
