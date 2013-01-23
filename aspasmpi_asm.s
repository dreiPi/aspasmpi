.globl _calc
# void calc(float* data1, float* data2, float* result1, float* result2, int length)
# r0 = data1 -> [r11,#-0x8]
# r1 = data2 -> [r11,#-0xc]
# r2 = result1 -> [r11,#-0x10]
# r3 = result2 -> [r11,#-0x14]
# stack = length -> r0
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
	LDR r0, [r11,#4]
	STR r0, [r11,#-0x18]
	# r0 := length
	
	# Hier fängt die eigentliche Methode an
	# Pointer für Arrays holen
	LDR r1, [r11,#-0x8]
	LDR r2, [r11,#-0xc]
	LDR r3, [r11,#-0x10]
	LDR r4, [r11,#-0x14]

	# Konstante 4*PI*E0 vorberechnen
	# Konstanten laden: s0 := PI, s3 := E0
	FLDS s0, _M_PI
	FLDS s3, _E_0
	# s0 := pi*e0
	FMULS s0, s0, s3
	# s3 := 4.0
	FLDS s3, _M_4
	# s3 := 4*pi*e0, die Konstane ist nun in s3 gespeichert
	FMULS s3, s0, s3
	
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
	FLDS s0, [r5]
	FLDS s1, [r6]
	# Dielekrizität für Hartgummi laden
	FLDS s2, _E_GUMMI

	# Springe zu _capacity, um die Kapazität zu berechnen
	BL _capacity
	# Ergebnis speichern
	FSTS s0, [r7]

	# Datensatz wieder einlesen
	FLDS s0, [r5]
	FLDS s1, [r6]
	# Dielekrizität für Hartpapier laden
	FLDS s2, _E_PAPIER

	# Springe zu _capacity, um die Kapazität zu berechnen
	BL _capacity
	# Ergebnis speichern
	FSTS s0, [r8]

	# Zählvariable dekrementieren
	SUBS r0, r0, #1
	# SUB mit S aktualisiert N Flag, wodurch ein Über/Unterlauf angezeigt wird
	# Falls r0 >= 0, also kein Überlauf, mache weiter
	BPL loop

	# Aufräumen
	# Gespeichertes Link Register holen
	POP {lr}
	# Stackframe zurücksetzen
	SUB sp, r11, #0x1c
	# Register und Stackframe POPpen
	POP {r4-r10,r11}
	# Fertig.
	BX lr

.globl _capacity
# float capacity(float rad1, float rad2, float er, float _4_pi_e0)
# s0 = rad1
# s1 = rad2
# s2 = er
# s3 = _4_pi_e
_capacity :
	# Setup
	# Register und Strackframe pushen
	PUSH {r5-r7,r11}
	# neuen Stackframe erstellen
	ADD r11,sp, #0xc
	# Platz in den VFP-Registern schaffen
	FMRS r5, s3
	FMRS r6, s4
	FMRS r7, s5
	PUSH {r5-r7}

	# Bruch ausrechnen

	# s4 := rad2-rad1
	FSUBS s4, s1, s0

	# s4 := rad1/(rad2-rad1)
	FDIVS s4, s0, s4

	# s4 := rad1*rad2 / (rad2-rad1)
	FMULS s4, s4, s1
	
	# s0 := 4*pi*e0*er
	FMULS s0, s3, s2

	# Kapazität berechnen (Bruch * Konstante)
	FMULS s0, s0, s4
	# Ergebnis ist jetzt in s0

	# VFP-Register wiederherstellen
	POP {r5-r7}
	FMSR s3, r5
	FMSR s4, r6
	FMSR s5, r7
	# Teardown
	# Reset stackframe
	SUB sp, r11, #0xc
	# Register und Stackframe popen
	POP {r5-r7,r11}
	# Weiter
	BX lr

_E_0 :
	.float 8.85418781762e-12
_M_PI :
	.float 3.14159265358979323846
_M_4 :
	.float 4.0
_E_GUMMI :
	.float 3.0
_E_PAPIER :
	.float 5.0
