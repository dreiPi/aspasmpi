.globl _asm_transpMatrix
## void asm_transp_matrix(float* matrix, float* result)
## rX = matrix
## rY = result
_asm_transpMatrix :
	## Setup
	## PUSH registers and stackframe
	##PUSH {r11}
	##MOV r11, sp
	# Create new stckfrme
	##SUB sp, sp, #0x0c
	# cpy prms
	##STR r0, [r11, #-0x08]
	##STR r1, [r11, #-0x0c]
	# loooooooop init
	MOV r4, #0 ;# Zählvariable i = r4
	MOV r5, #0 ;# Zählvariable j = r5

loop :
	# ld
	LSL r9, r4, #3
	ADD r6, r5, r9				;# 8*i+j + r0 := quellspeicher
	LSL r6, r6, #2
	ADD r6, r6, r0

	LSL r9, r5, #3
	ADD r7, r4, r9				;# 8*j+i + r1 := zielspeicher
	LSL r7, r7, #2
	ADD r7, r7, r1

	# sve
	LDR r8, [r6]
	STR r8, [r7]

	# lp
	ADD r5, r5, #1
	CMP r5, #8
	BLT loop
	ADD r4, r4, #1
	CMP r4, #8
	MOV r5, #0
	BLT loop

	## Trdwn

	## Reset stackframe
	# POP registers and stackfrm
	# Return
	BX lr


.globl _asm_task
## int asm_task(int, int, int)
_asm_task :
	ADD r0, r0, r1
	ADD r0, r0, r2
	BX lr

