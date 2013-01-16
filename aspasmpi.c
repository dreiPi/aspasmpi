#include <stdio.h>
#include <sys/time.h>

#define M_PI		3.14159265358979323846
#define E_0			8.85418781762e-12
#define E_GUMMI		3.0
#define E_PAPIER	5.0

extern void _calc(float* data1, float* data2, float* result1, float* result2, int length);
extern float _capacity(float rad1, float rad2, float er);

float calc_single_c (float r1, float r2, float e_r);
void calc_c(float* data1, float* data2, float* result1, float* result2, int length);

int main(int argc, char **argv) {
	struct timeval start, ende;
	gettimeofday(&start,0);
	
	//calc(...)
	float r1 = 0.9f, r2 = 1.0f, e = E_GUMMI;
	float res = _capacity(r1, r2, e);
	float res_c = calc_single_c(r1, r2, e);
	printf("ergebnis: %e\n", res);
	printf("ergebnis c: %e\n", res_c);

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

float calc_single_c (float r1, float r2, float e_r) {
	float faktor, bruch, k1;
	faktor = 4 * M_PI * E_0;
	bruch = (r2 * r1) / (r2 - r1);
	k1 = faktor * bruch * e_r;
	return k1;
}
