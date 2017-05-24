MACRO 	PUSH( _data_, _ptr_)
	sto	_data_,_ptr_
	add.i	_ptr_,r0,1
ENDMACRO

MACRO	POP( _data_, _ptr_)
	add.i	_ptr_,r0,-1
	ld	_data_, _ptr_
ENDMACRO
	
	ld.i	r14, r0,STACK 	# Setup global stack pointer
	ld.i	r10,r0, DATA0-2 # R10 points to multiplier data (will be preincremented)
	ld.i	r12,r0, RESULTS # R12 points to area for results
	
outer:	add.i	r10,r0,2	# increment data pointer by 2
	ld	r2,r10	        # check if we reached the (0,0) word  
	add	r2,r10,1	
	z.ld.i	pc,r0,end	# .. if yes, bail out 
	ld.i	r11,r0, DATA0   # reset multiplicand pointer
inner:
	ld.i 	r1, r10		# get multiplier address A
	ld.i	r2, r11		# get multiplicand address B
	ld.i	r3, r12		# get result area pointer
	ld.i	r13,r0, next	# save return address
	ld.i 	pc, r0, multiply32	# JSR multiply32
next:	add.i	r12,r0,4	# increment result pointer by 4
	add.i	r11,r0,2	# increment multiplicand address by 2
	ld	r2,r11		# get multiplicand data LSW
	add	r2,r11,1	# get multiplicand data MSW
	z.ld.i	pc,r0,outer	# if (0,0) then next outer loop
	ld.i	pc,r0,inner	# else next inner loop

end:	
	halt	r0,r0,0x99

	# --------------------------------------------------------------
	#
	# multiply32
	#
	# Entry:
	# 	r1 points to block of two bytes holding 32 bit multiplier (A), LSB in lowest byte
	# 	r2 points to block of two bytes holding 32 bit multiplicand (B), LSB in lowest byte
	#	r3 points to area of memory large enough to take the 4 byte result
	#	r13 holds return address
	#	(r14 is global stack pointer)
	# Exit
	# 	r1..9 uses as workspace registers and trashed
	#	Result written to memory (see above)
	# --------------------------------------------------------------	
multiply32:
	PUSH	(r13, r14)	# save return address
	PUSH	(r3, r14)	# save results pointer
	
	ld 	r8, r2, 1	# Get B into r7,r8 (pre-shifted)
	ld 	r7, r2 
	ld.i 	r6, r0
	ld.i 	r5, r0		

	ld.i 	r4, r0		# Get A into r1..r4
	ld.i 	r3, r0
	ld 	r2, r1, 1
	ld 	r1, r1		

	ld.i	r9, r0,-32	# Setup a loop counter
mulstep32:
	add.i	r0,r0		# clear carry
	ror.i	r4,r4
	ror.i	r3,r3
	ror.i	r2,r2
	ror.i	r1,r1
	nc.ld.i	pc,r0,mcont	# if not carry skip adds
	add.i	r1,r5
	adc.i	r2,r6
	adc.i	r3,r7
	adc.i	r4,r8
mcont:	add.i	r9,r0,1		# increment counter
	nz.ld.i	pc,r0,mulstep32	# next iteration if not zero

	add.i	r0,r0		# clear carry
	ror.i	r4,r4
	ror.i	r3,r3
	ror.i	r2,r2
	ror.i	r1,r1		
	POP	(r5, r14)	# get result pointer	
	sto 	r1,r5,0		# save results
	sto 	r2,r5,1
	sto 	r3,r5,2
	sto 	r4,r5,3		
	POP	(r13,r14)	# get return address
	ld.i	pc,r13		# and return

	
	ORG	0x200
STACK:	WORD 0,0,0,0,0,0,0,0,0	# Reserve some stack space 

DATA0: 	WORD 0x02,0x04,0x08,0x03
	WORD 0x00,0x09,0x18,0x23
	WORD 0x13,0x03,0x08,0x00
	WORD 0x00,0x44,0x33,0x99
	WORD 0x11,0x00,0xF8,0x03
	WORD 0xC2,0x04,0xAB,0x03
	WORD 0x00,0x00,0x00,0x00	# all zero words to finish

	ORG	0x300
RESULTS:	



