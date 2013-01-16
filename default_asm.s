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
	ADD r11,sp, #40
	SUB sp, sp, #20
	# copy params
	STR r0, [r11,#-0x8]
	STR r1, [r11,#-0xc]
	STR r2, [r11,#-0x10]
	STR r3, [r11,#-0x14]
	LDR r0, [r11,#4]
	STR r0, [r11,#-0x18]

	##Code:
	##TODO
	## Teardown

	## Reset stackframe
	SUB sp, r11, #40
	# POP registers and stackframe
	POP {r4-r10,r11}
	# Return
	BX lr