.globl _calc
## void calc(float* data1, float* data2, float* result1, float* result2, int length)
## r0 = data1 -> [r11,#-0x8]
## r1 = data2 -> [r11,#-0xc]
## r2 = result1 -> [r11,#-0x10]
## r3 = result2 -> [r11,#-0x14]
## stack length -> [r11,#-0x18]
## e1*pi -> r9
## e2*pi -> r10
_calc :
	## Setup
	## PUSH registers and stackframe
	PUSH {r4-r10,r11}
	# Create new stackfrme
	ADD r11,sp, #0x1c
	SUB sp, sp, #20
	# copy params
	STR r0, [r11,#-0x8]
	STR r1, [r11,#-0xc]
	STR r2, [r11,#-0x10]
	STR r3, [r11,#-0x14]
	PUSH {lr}

	LDR r0, [r11,#4]
	STR r0, [r11,#-0x18]
	## r0 := length
	##Code:
	##Basispointer laden
	LDR r1, [r11,#-0x8]
	LDR r2, [r11,#-0xc]
	LDR r3, [r11,#-0x10]
	LDR r4, [r11,#-0x14]
	SUB r0, r0, #1
loop :
	## Pointer für alles, jeweils mit Offset i<<2
	ADD r5, r1, r0, LSL #2
	ADD r6, r2, r0, LSL #2
	ADD r7, r3, r0, LSL #2
	ADD r8, r4, r0, LSL #2

	FLDS s0, [r5]
	FLDS s1, [r6]
	FLDS s2, _E_GUMMI
	## Kapazität berechnen
	BL _capacity
	FSTS s0, [r7]

	FLDS s0, [r5]
	FLDS s1, [r6]
	FLDS s2, _E_PAPIER
	## Kapazität berechnen
	BL _capacity
	FSTS s0, [r8]

	## SUBS aktualisiert N Flag
	SUBS r0, r0, #1
	## Branch if not negative
	BPL loop


	## Teardown
	POP {lr}
	## Reset stackframe
	SUB sp, r11, #0x1c
	# POP registers and stackframe
	POP {r4-r10,r11}
	# Return
	BX lr


.globl _capacity
## float capacity(float rad1, float rad2, float er)
## r0 = rad1 -> [r11,#-0x8]
## r1 = rad2 -> [r11,#-0xc]
## r2 = e_r -> [r11,#-0x10]
_capacity :
	## Setup
	## PUSH registers and stackframe
	PUSH {r5-r7,r11}
	# Create new stackfrme
	ADD r11,sp, #0xc
	##Code:
	## Platz in den VFP-Registern
	FMRS r5, s3
	FMRS r6, s4
	FMRS r7, s5
	PUSH {r5-r7}

	## Faktor ausrechnen
	FLDS s3, _M_PI
	FLDS s4, _E_0

	## s3 := pi*e0
	FMULS s3, s3, s4

	## float 4.0
	FLDS s4, _M_4

	## s3 := 4*pi*e0
	FMULS s3, s3, s4

	## e_r
	FCPYS s4, s2

	## s3 := 4*pi*e0*er
	FMULS s3, s3, s4

	## Bruch ausrechnen

	## rad1
	FCPYS s4, s0
	## rad2
	FCPYS s5, s1

	## s4 := rad2-rad1
	FSUBS s4, s5, s4

	## s5 := rad1
	FCPYS s5, s0

	## s4 := rad1/(rad2-rad1)
	FDIVS s4, s5, s4

	## s5 := rad2
	FCPYS s5, s1

	## s4 := rad1*rad2 / (rad2-rad1)
	FMULS s4, s4, s5

	## s3 := kapazität
	FMULS s3, s3, s4

	## ergebnis schreiben
	FCPYS s0, s3

	## VFP-Register wiederherstellen
	POP {r5-r7}
	FMSR s3, r5
	FMSR s4, r6
	FMSR s5, r7
	## Teardown
	## Reset stackframe
	SUB sp, r11, #0xc
	# POP registers and stackframe
	POP {r5-r7,r11}
	# Return
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

