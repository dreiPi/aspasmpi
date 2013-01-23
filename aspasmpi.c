#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/resource.h>

#define MAX_LINE_LENGTH 1024

#define M_PI		3.14159265358979323846
#define E_0			8.85418781762e-12
#define E_GUMMI		3.0
#define E_PAPIER	5.0

extern void _calc(float* data1, float* data2, float* result1, float* result2, int length);
extern float _capacity(float rad1, float rad2, float er);

int read_file(char* filename, float** rad1, float** rad2, int* length);
float calc_single_c (float r1, float r2, float e_r);
void calc_c(float* data1, float* data2, float* result1, float* result2, int length);

int main(int argc, char **argv) {

	float *rad1, *rad2, *result1, *result2;
	int length;
	int erfolg = read_file("ui.txt", &rad1, &rad2, &length);
	if(erfolg != 0) {
		return erfolg;
	}
	result1 = (float*)malloc(length * sizeof(float));
	result2 = (float*)malloc(length * sizeof(float));

	struct rusage start,end;
	rusage(RUSAGE_SELF,&start);
	_calc(rad1, rad2, result1, result2, length);
	rusage(RUSAGE_SELF,&end);

	printf("ARM: time needed: %li usec \n", (start.ru_utime.tv_sec+start.ru_stime.tv_sec));

	printf("Ergebnisse: \n");
	printf("index     r1             r2             k_gummi        k_papier\n");
	for(int i=0; i<length; i++) {
		printf("%8d: %1.8e %1.8e %1.8e %1.8e\n", i,
				rad1[i],rad2[i],result1[i],result2[i]);
	}

	printf("C: time needed: %li usec \n", 1);

	printf("Ergebnisse: \n");
	printf("index     r1             r2             k_gummi        k_papier\n");
	for(int i=0; i<length; i++) {
		printf("%8d: %1.8e %1.8e %1.8e %1.8e\n", i,
				rad1[i],rad2[i],result1[i],result2[i]);
	}



	return 0;
}

int read_file(char* filename, float** rad1, float** rad2, int* length) {
	FILE* handle = NULL;
	char line[MAX_LINE_LENGTH];

	handle = fopen(filename, "r");
	if(!handle) {
		fprintf(stderr,"FEHLER: Datei konnte nicht geoeffnet werden!\n");
		return 1;
	}
	//erste zeile einlesen
	if(feof(handle)) {
		fprintf(stderr,"Fehler: Datei ist leer\n");
		return 1;
	}
	if(fgets(line, MAX_LINE_LENGTH, handle)==NULL) {
		fprintf(stderr,"Fehler: Datei ist leer\n");
		return 1;
	}
	*length = atoi(line);
	if(*length <= 0) {
		fprintf(stderr, "Fehler: '%s' ist keine sinnvolle Zeilennummer\n", line);
		return 1;
	}
	//allokiere speicher
	*rad1 = (float*)malloc(*length * sizeof(float));
	*rad2 = (float*)malloc(*length * sizeof(float));
	if(!rad1 || !rad2) {
		fprintf(stderr,"Fehler: keinen Speicher bekommen\n");
		return 1;
	}

	//werte lesen
	int index = 0;
	while(!feof(handle)) {

		if(fgets(line, MAX_LINE_LENGTH, handle) == NULL) break;
		if(sscanf(line, "%f mm %f mm",
				(*rad1+index), (*rad2+index) ) != 2) {
			fprintf(stderr, "Fehler in Z. %d: %s\n", index, line);
			fprintf(stderr, "Ich bin mal weg\n");
			return 1;
		}
		index++;
		if(index > *length) {
			fprintf(stderr,"Fehler: zu viele Werte, letzter wert: %s\n",line);
			break;
		}
	}
	if(index != *length) {
		fprintf(stderr,"Fehler: zu wenige Werte\n");
		*length = index;
	}
	return 0;
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
