#include <stdio.h>
#include <sys/time.h>

int _asm_task(int, int, int);

int main(int argc, char **argv) {
	struct timeval start, ende;
	gettimeofday(&start,0);
	if(1 || 0 && 1 ^ 0) {
		printf("ergebnis = %d \n", _asm_task(1,2,3));
	}
	gettimeofday(&ende, 0);
	printf("time needed: %d usec \n", (ende.tv_sec - start.tv_sec)*1000000+ende.tv_usec-start.tv_usec);
	return 0;
}
