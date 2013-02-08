#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <sys/time.h>
#include <assert.h>

#define MAX_LINE_LENGTH 1024

#define M_PI		3.14159265358979323846
#define E_0			8.85418781762e-12
#define E_GUMMI		3.0
#define E_PAPIER	5.0

/**
 * Führt die Berechnung der Kapazitäten aller angegebener Datensätze an.
 * Verwendet dazu die Methode _capacity().
 * @param data1 ein Array, in dem die inneren Radien gespeichert sind
 * @param data2 ein Array, in dem die äußeren Radien gespeichert sind
 * @param result1 in diesem Array werden die Ergebnisse für Hartgummi gespeichert
 * @param result2 in diesem Array werden die Ergebnisse für Hartpapier gespeichert
 * @param length die Länge aller Arrays
 */
extern void _calc(float* data1, float* data2, float* result1, float* result2, int length);

/**
 * Berechnet die Kapazität eines Kugelkondensators
 * @param r1 innerer Radius
 * @param r2 äußerer Radius
 * @param er Dielektrizität für das verwendete Material
 * @param _4_pi_e0 eine vorgegebene Konstante, 4*pi*e0
 * @return die Kapazität des Kugelkondensators
 */
extern float _capacity(float rad1, float rad2, float er, float _4_pi_e0);

/**
 * Berechnet die Kapazität von 4 Kugelkondensatoren mit jeweils 2 Dielektrika
 * @param r1 ein 4 Elemente großes Array, in dem die inneren Radien gespeichert sind
 * @param r2 ein 4 Elemente großes Array, in dem die äußeren Radien gespeichert sind
 * @param er ein 2 Elemente großes Array, in dem die Dielektrizitäten für die verwendeten Materialien gespeichert sind
 * @param res1 Ergebnisse für Dielektrizitätswert 1
 * @param res2 Ergebnisse für Dielektrizitätswert 2
 */
extern void _fast_capacity(float* r1, float* r2, float* er, float* res1, float* res2);

// Vordeklarationen

int datei_lesen(char* filename, float** rad1, float** rad2, int* length);

float capacity_c (float r1, float r2, float e_r);
void calc_c(float* data1, float* data2, float* result1, float* result2, int length);

// Hauptprogramm
int main(int argc, char **argv) {
	// Pointer für unsere Arrays freimachen
	float *rad1, *rad2, *result1, *result2;
	int length;
	// Datei einlesen
	int erfolg = datei_lesen("ui.txt", &rad1, &rad2, &length);
	if(erfolg != 0) {
		return erfolg;
	}
	// Speicher allokieren
	result1 = (float*)malloc(length * sizeof(float));
	result2 = (float*)malloc(length * sizeof(float));

	//Sicherstellen dass der Speicher korrekt allokiert wurde
	assert((result1!=NULL&&result2!=NULL));
	// Zeitmessung
	struct timeval start,end;
	gettimeofday(&start,0);
	// Assemblermethode aufrufen
	_calc(rad1, rad2, result1, result2, length);
	gettimeofday(&end,0);

	// Zeitberechnung
	double utimediff = (end.tv_sec - start.tv_sec) * 1000000.0 + (end.tv_usec - start.tv_usec);

	printf("ARM: time needed: %f usec \n", utimediff);

	// das erste, 1/3ste, 2/3ste und letzte Ergebnis ausgeben
	printf("Ergebnisse der Assemblerimplementierung: \n");
	printf("index     r1             r2             k_gummi        k_papier\n");
	for(int i=0; i<length; i+=length/3) {
		printf("%8d: %1.8e %1.8e %1.8e %1.8e\n", i,
				rad1[i],rad2[i],result1[i],result2[i]);
	}

	// Dasselbe mit der NEON-Methode
	gettimeofday(&start,0);
	float er[2] = {E_GUMMI,E_PAPIER};
	for(int i=0;i<length-4;i+=4) {
		_fast_capacity(rad1+i, rad2+i, er, result1+i, result2+i);
	}
	gettimeofday(&end,0);

	// Zeitberechnung
	utimediff = (end.tv_sec - start.tv_sec) * 1000000.0 + (end.tv_usec - start.tv_usec);

	printf("NEON: time needed: %f usec \n", utimediff);

	// das erste, 1/3ste, 2/3ste und letzte Ergebnis ausgeben
	printf("Ergebnisse der NEON-Implementierung: \n");
	printf("index     r1             r2             k_gummi        k_papier\n");
	for(int i=0; i<length; i+=length/3) {
		printf("%8d: %1.8e %1.8e %1.8e %1.8e\n", i,
				rad1[i],rad2[i],result1[i],result2[i]);
	}

	// Das selbe nochmal mit der Referenzimplementierung wiederholen
	gettimeofday(&start,0);
	calc_c(rad1, rad2, result1, result2, length);
	gettimeofday(&end,0);

	utimediff = (end.tv_sec - start.tv_sec) * 1000000.0 + (end.tv_usec - start.tv_usec);

	printf("C: time needed: %f usec \n", utimediff);

	printf("Ergebnisse der Referenzimplementierung: \n");
	printf("index     r1             r2             k_gummi        k_papier\n");
	for(int i=0; i<length; i+=length/3) {
		printf("%8d: %1.8e %1.8e %1.8e %1.8e\n", i,
				rad1[i],rad2[i],result1[i],result2[i]);
	}
	
	free(result1);
	free(result2);
	free(rad1);
	free(rad2);

	return 0;
}


/**
 * Lies die angegebene Datei ein, die erste Zeile soll die Anzahl der Datensätze enthalten,
 * Alle weiteren Zeilen sind im Format '## mm ## mm',
 * wobei ## jeweils eine Fließkommazahl mit Punkt als Dezimaltrennzeichen ist.
 * @param filename der Pfad zur Datei
 * @param rad1 ein Pointer auf einen float-Pointer,
 * in diesem wird ein Array für die inneren Radien gespeichert
 * @param rad2 wie rad1, aber für die äußeren Radien
 * @param length ein Pointer auf eine float-Variable, dort wird die Länge der beiden Arrays gespeichert.
 * @return 0, wenn erfolgreich, 1 im Fehlerfall
 */
int datei_lesen(char* filename, float** rad1, float** rad2, int* length) {
	// hier kommt unser Handle rein
	FILE* handle = NULL;
	char line[MAX_LINE_LENGTH];
	
	// Datei öffnen
	handle = fopen(filename, "r");
	if(!handle) {
		fprintf(stderr,"FEHLER: Datei konnte nicht geoeffnet werden!\n");
		return 1;
	}
	// erste Zeile einlesen
	if(feof(handle) || fgets(line, MAX_LINE_LENGTH, handle)==NULL) {
		fprintf(stderr,"Fehler: Datei ist leer\n");
		return 1;
	}
	// die Zahl in der ersten Zeile ist die Anzahl der Datensätze
	*length = atoi(line);
	if(*length <= 0) {
		fprintf(stderr, "Fehler: '%s' ist keine sinnvolle Zeilennummer\n", line);
		return 1;
	}
	// Speicherallokation
	*rad1 = (float*)malloc(*length * sizeof(float));
	*rad2 = (float*)malloc(*length * sizeof(float));
	if(!rad1 || !rad2) {
		fprintf(stderr,"Fehler: keinen Speicher bekommen\n");
		return 1;
	}

	// Werte lesen
	int index = 0;
	while(!feof(handle)) {
		// solange wir nicht am Ende der Datei sind und fgets() etwas einlesen kann
		if(fgets(line, MAX_LINE_LENGTH, handle) == NULL) break;
		// parse die zwei Werte
		if(sscanf(line, "%f mm %f mm",
				// hier werden die Pointer berechnet, in denen dann die Werte gespeichert werden
				(*rad1+index), (*rad2+index) ) != 2) {
			// es wurden nicht genau 2 Zahlen gefunden, Schiff verlassen!
			fprintf(stderr, "Fehler in Z. %d: %s\n", index, line);
			fprintf(stderr, "Ich bin mal weg\n");
			return 1;
		}
		index++;
		if(index > *length) {
			// Es wurden zu viele Werte eingelesen, wir ignorieren den rest und fahren fort.
			fprintf(stderr,"Fehler: zu viele Werte, letzter Wert: %s\n",line);
			break;
		}
	}
	if(index != *length) {
		// Es wurden zu wenige Werte eingelesen, wir ändern die Länge und fahren fort.
		// Den überschüssigen Speicher ignorieren wir.
		fprintf(stderr,"Fehler: zu wenige Werte\n");
		*length = index;
	}
	
	// Datei-Handle schließen 
	if(!fclose(handle)) {
		fprintf(stderr, "Fehler: Konnte Eingabedatei nicht schließen.\n");
	}
	
	return 0;
}

/**
 * Referenzimplementierung des Assemblercodes in C.
 * Führt die Berechnung der Kapazitäten aller angegebener Datensätze an.
 * @param data1 ein Array, in dem die inneren Radien gespeichert sind
 * @param data2 ein Array, in dem die äußeren Radien gespeichert sind
 * @param result1 in diesem Array werden die Ergebnisse für Hartgummi gespeichert
 * @param result2 in diesem Array werden die Ergebnisse für Hartpapier gespeichert
 * @param length die Länge aller Arrays
 */
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

/**
 * Referenzimplementierung des Assemblerodes in C.
 * Berechnet einen einzigen Wert
 * @param r1 innerer Radius
 * @param r2 äußerer Radius
 * @param e_r Dielektrizität für das verwendete Material
 * @return die Kapazität des Kugelkondensators
 */
float capacity_c (float r1, float r2, float e_r) {
	float faktor, bruch, k1;
	faktor = 4 * M_PI * E_0;
	bruch = (r2 * r1) / (r2 - r1);
	k1 = faktor * bruch * e_r;
	return k1;
}
