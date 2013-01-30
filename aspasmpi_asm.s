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
	FLDS s3, _M_E_0
	## s0 := pi*e0
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

# float* fast_capacity(float* r1, float* r2, float* ers, float* res1, float* res2)

# first two e_rs are evaluated
.globl _fast_capacity
_fast_capacity :
	PUSH {r11}
	ADD r11,sp,#0x0
	# 6 register * sizeof(float) * quad
	VPUSH {q0-q5}

	# 2 x e_r
	VLDM r2, {d0}
	# 4 x r1
	VLDM r0, {q1}
	# 4 x r2
	VLDM r1, {q2}
	# r2 - r1
	VSUB.F32 q4, q2, q1
	# 1 / (r2 - r1)
	VRECPE.F32 q3, q4
	# q3 = x0
	# q4 = d

	# mehr genauigkeit
	# q4 := 2 - x*d
	VRECPS.F32 q5, q3, q4
	# q4 := x0 * (2-x*d)
	VMUL.F32 q3, q5, q3

	# dasselbe nochmal
	VRECPS.F32 q5, q3, q4
	VMUL.F32 q3, q5, q3
	# q3 := xn

	# r1 / (r2 - r1)
	VMUL.F32 q3, q3, q1
	# r2 * r1 / (r2 - r1)
	VMUL.F32 q3, q3, q2
	# e_0 * 4 * pi
	VLDR d1, _M_4_PI
	VMUL.F32 q3, q3, d1[0]
	VMUL.F32 q3, q3, d1[1]
	VLDR d1, _M_E_0
	VMUL.F32 q3, q3, d1[0]
	# ergebnis
	VMUL.F32 q4, q3, d0[0]
	VMUL.F32 q5, q3, d0[1]

	VSTM r3, {q4}
	LDR r0, [r11,#0x4]
	VSTM r0, {q5}


	VPOP {q0-q5}
	SUB sp,r11, #0x0
	POP {r11}
	BX lr

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
_E_CONST :
	.float 1.112650056053569442110823386467834993628329236e-10
_M_4_PI :
	.float 3.14159265358979323846
	.float 4.0

