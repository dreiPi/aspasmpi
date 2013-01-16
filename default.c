#include <stdio.h>
#include <sys/time.h>

int calc(float* data1, float* data2, float* resul1, float* result2, int length);

int main(int argc, char **argv) {
	struct timeval start, ende;
	gettimeofday(&start,0);
	
	//calc(...)

	gettimeofday(&ende, 0);
	printf("time needed: %d usec \n", (ende.tv_sec - start.tv_sec)*1000000+ende.tv_usec-start.tv_usec);
	return 0;

	//TODO Rahmenprogramm
}
