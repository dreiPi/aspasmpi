# void calc(float* data1, float* data2, float* result1, float* result2, int length)
# Berechnung der Kapazitäten von Kugelkondensatoren mit jeweils den Dielektrizitätswerten von Hart(gummi|papier)
# data1: innerer Radius der Kondensatoren
# data2: äußerer Radius der Kondensatoren
# result1: Ergebnisse der Berechnung mit Hartgummi
# result2: Ergebnisse der Berechnung mit Hartpapier
# length: Anzahl der zu berechnenden Kapazitäten/Länge des Datensatzes

# r0 = data1 -> [r11,#-0x8]
# r1 = data2 -> [r11,#-0xc]
# r2 = result1 -> [r11,#-0x10]
# r3 = result2 -> [r11,#-0x14]
# stack = length -> r0
.globl _calc
_calc :
	# Stackframe Einrichten
	# Register und Stackframe PUSHen
	PUSH {r4-r10,r11}
	
	# neuen Stackframe erstellen
	ADD r11,sp, #0x1c
	SUB sp, sp, #20
	# Parameter kopieren
	STR r0, [r11,#-0x8]
	STR r1, [r11,#-0xc]
	STR r2, [r11,#-0x10]
	STR r3, [r11,#-0x14]
	# Link Register speichern
	PUSH {lr}

	# Länge aus dem Stack laden und im Stackframe speichern
	# r0 := length
	LDR r0, [r11,#4]
	STR r0, [r11,#-0x18]
	
	# Hier fängt die eigentliche Methode an
	# Pointer für Arrays holen
	LDR r1, [r11,#-0x8]
	LDR r2, [r11,#-0xc]
	LDR r3, [r11,#-0x10]
	LDR r4, [r11,#-0x14]

	# Konstante 4*PI*E0 vorberechnen
	# Konstanten laden: s0 := PI, s3 := E0
	VLDR.F32 s0, _M_PI
	VLDR.F32 s3, _M_E_0
	## s0 := pi*e0
	VMUL.F32 s0, s0, s3
	# s3 := 4.0
	VLDR.F32 s3, _M_4
	# s3 := 4*pi*e0, die Konstane ist nun in s3 gespeichert
	VMUL.F32 s3, s0, s3
	
	# Wir fangen bei Länge-1 an und zählen dann herunter bis r0==0
	SUB r0, r0, #1
loop :
	# Pointer für den Datensatz und die Ergebnisse berechnen
	# jeweils mit Offset r0 und LSL #2, da ein float 4 Bytes sind
	ADD r5, r1, r0, LSL #2
	ADD r6, r2, r0, LSL #2
	ADD r7, r3, r0, LSL #2
	ADD r8, r4, r0, LSL #2

	# Datensatz lesen
	VLDR.F32 s0, [r5]
	VLDR.F32 s1, [r6]
	# Dielekrizität für Hartgummi laden
	VLDR.F32 s2, _E_GUMMI

	# Springe zu _capacity, um die Kapazität zu berechnen
	BL _capacity
	# Ergebnis speichern
	VSTR.F32 s0, [r7]

	# Datensatz wieder einlesen
	VLDR.F32 s0, [r5]
	VLDR.F32 s1, [r6]
	# Dielekrizität für Hartpapier laden
	VLDR.F32 s2, _E_PAPIER

	# Springe zu _capacity, um die Kapazität zu berechnen
	BL _capacity
	# Ergebnis speichern
	VSTR.F32 s0, [r8]
	

	# Zählvariable dekrementieren
	SUBS r0, r0, #1
	# SUB mit S aktualisiert N Flag, wodurch ein Über/Unterlauf angezeigt wird
	# Falls r0 >= 0, also kein Überlauf, mache weiter (springe zurück an Schleifenanfang)
	BPL loop

	# Aufräumen
	# Gespeichertes Link Register holen
	POP {lr}
	# Stackframe zurücksetzen
	SUB sp, r11, #0x1c
	# Register und Stackframe POPpen
	POP {r4-r10,r11}
	# Fertig (Rücksprung an Aufrufer)
	BX lr

# float capacity(float rad1, float rad2, float er, float _4_pi_e0)

# Berechnung der Kapzität eines Kugelkondensators 
# rad1: innerer Radius des Kugelkondensators 
# rad2: äußerer Radius des Kugelkondensators
# er: Dielektrizitätswert
# _4_pi_e0: konstanter Teil 4.0 * pi * e_0
# -> Ergebnis ist in Register s0

.globl _capacity
_capacity :
	# Setup
	# Register und Strackframe pushen
	PUSH {r5-r7,r11}
	# neuen Stackframe erstellen
	ADD r11,sp, #0xc
	# Platz in den VFP-Registern schaffen
    VPUSH {s3-s5}

	# Bruch ausrechnen

	# s4 := rad2-rad1
	VSUB.F32 s4, s1, s0

	# s4 := rad1/(rad2-rad1)
	VDIV.F32 s4, s0, s4

	# s4 := rad1*rad2 / (rad2-rad1)
	VMUL.F32 s4, s4, s1
	
	# s0 := 4*pi*e0*er
	VMUL.F32 s0, s3, s2

	# Kapazität berechnen (Bruch * Konstante)
	VMUL.F32 s0, s0, s4
	# Ergebnis ist jetzt in s0

	# VFP-Register wiederherstellen
	VPOP {s3-s5}
	# Teardown
	# Reset stackframe
	SUB sp, r11, #0xc
	# Register und Stackframe POPpen
	POP {r5-r7,r11}
	# Rücksprung an Aufrufer
	BX lr

# void fast_capacity(float* r1, float* r2, float* er, float* res1, float* res2)

# Benutzt NEON-Befehle zum gleichzeitigen Berechnen der Kapazität von 4 Kugelkondensatoren mit jeweils 2 Dielektrizitätswerten
# r1: 4 x innerer Radius der Kugelkondensatoren
# r2: 4 x äußerer Radius der Kugelkondensatoren
# er: 2 x Dielektrizitätswert
# res1: Ergebnisse mit Dielektrizitätswert 1
# res2: Ergebnisse mit Dielektrizitätswert 2

.globl _fast_capacity
_fast_capacity :
	# Stackframe sichern
	PUSH {r11}
	ADD r11,sp,#0x0
	
	# Vorherige Registerwerte sichern
	VPUSH {q0-q5}

	# d0 := 2 Dielektrizitätswerte laden
	VLDM r2, {d0}
	# q1 := 4 rad1 laden
	VLDM r0, {q1}
	# q2 := 4 rad2 laden
	VLDM r1, {q2}
	
	# Berechnung der Kapazität
	
	# q4 := rad2 - rad1
	VSUB.F32 q4, q2, q1
	
	# Kehrbruchapproximation, da NEON keine Division unterstützt
	# q3 := 1 / (rad2 - rad1)
	# Newton-Raphson-Iteration (Approximation von 1/d)
	# x_n+1 = x_n * (2 - x_n * d)
	
	# Erster Iterationsschritt
	# q3 := x_0
	# q4 := d
	VRECPE.F32 q3, q4

	# Zweiter Iterationsschritt
	# q5 := 2 - x_0 * d
	VRECPS.F32 q5, q3, q4
	
	# q3 := x_1 = x_0 * (2 - x_0 * d)
	VMUL.F32 q3, q5, q3

	# Dritter Iterationsschritt
	# q5 := 2 - x_1 * d
	VRECPS.F32 q5, q3, q4
	
	# q3 := x_2 = x_1 * (2 - x_1 * d)
	VMUL.F32 q3, q5, q3
	
	# Fertig, Ergebnis ist ausreichend genau (~7 signifikante Stellen)

	# q3 := rad1 / (rad2 - rad1)
	VMUL.F32 q3, q3, q1
	
	# q3 := rad2 * rad1 / (rad2 - rad1)
	VMUL.F32 q3, q3, q2
	
	# Multiplizieren mit konstantem Teil
	# q3 := e_0 * pi * 4.0 * rad2 * rad1 / (rad2 - rad1)
	
	# d1 := 4.0, pi
	VLDR d1, _M_4_PI
	
	# q3 := 4.0 * rad2 * rad1 / (rad2 - rad1)
	VMUL.F32 q3, q3, d1[0]
	
	# q3 := pi * 4.0 * rad2 * rad1 / (rad2 - rad1)
	VMUL.F32 q3, q3, d1[1]
	
	# d1 := e_0, 0.0
	VLDR d1, _M_E_0
	
	# q3 := e_0 * pi * 4.0 * rad2 * rad1 / (rad2 - rad1)
	VMUL.F32 q3, q3, d1[0]
	
	# Berechnung des endgültigen Ergebnisses für die 2 Dielektrizitätswerte
	# q4 := e_r[0] * e_0 * pi * 4.0 * rad2 * rad1 / (rad2 - rad1)
	VMUL.F32 q4, q3, d0[0]
	# q5 := e_r[1] * e_0 * pi * 4.0 * rad2 * rad1 / (rad2 - rad1)
	VMUL.F32 q5, q3, d0[1]
	
	# Ergebnisse in q4 und q5
	# Zurückschreiben der Ergebnisse in den richtigen Speicherbereich
	
	# *res1 := q4
	VSTM r3, {q4}
	
	# *res2 := q5
	# Pointer aus dem Stack laden
	LDR r0, [r11,#0x4]
	VSTM r0, {q5}
	
	# Zurückschreiben der verwendeten Register und Stackframe
	VPOP {q0-q5}
	SUB sp,r11, #0x0
	POP {r11}
	
	# Rücksprung an Aufrufer
	BX lr

# Verwendete Konstanten (selbsterklärend)
_M_E_0 :
	.float 8.85418781762e-12
	.float 0.0
_M_PI :
	.float 3.14159265358979323846
_M_4 :
	.float 4.0
_E_GUMMI :
	.float 3.0
_E_PAPIER :
	.float 5.0
_M_4_PI :
	.float 3.14159265358979323846
	.float 4.0

