# --------------------------------------------------------------
#
# udiv16
#
# Divide a 16 bit number by a 16 bit number to yield a 16 b quotient and
# remainder
#
# Entry:
# - r1 16 bit dividend (A)
# - r2 16 bit divisor (B)
# - r13 holds return address
# - r14 is global stack pointer
# Exit
# - r6  upwards preserved
# - r3-5 trashed
# - r2 = quotient
# - r1 = remainder
# --------------------------------------------------------------
udiv16:
    mov     r3,r2                   # Get divisor into r3
    mov     r2,r0                   # Get dividend/quotient into double word r1,2
    mov     r4,r0, udiv16_loop      # Stash loop target in r4
    mov     r5,r0,-16               # Setup a loop counter
udiv16_loop:
    ASL     (r1)                    # shift left the quotient/dividend
    ROL     (r2)                    #
    cmp     r2,r3                   # check if quotient is larger than divisor
    c.sub   r2,r3                   # if yes then do the subtraction for real
    c.adc   r1,r0                   # ... set LSB of quotient using (new) carry
    add     r5,r0,1                 # increment loop counter zeroing carry
    nz.mov  pc,r4                   # loop again if not finished (r5=udiv16_loop)
    mov     pc,r13                  # and return with quotient/remainder in r1/r2

# --------------------------------------------------------------
#
# mul16
#
# Multiply 2 16 bit numbers to yield a 32b result
#
# Entry:
#       r1    16 bit multiplier (A)
#       r2    16 bit multiplicand (B)
#       r13   holds return address
#       r14   is global stack pointer
# Exit
#       r6    upwards preserved
#       r3,r5 uses as workspace registers and trashed
#       r1,r2 holds 32b result (LSB in r1)
#
#
#   A = |___r3___|____r1____|  (lsb)
#   B = |___r2___|____0_____|  (lsb)
#
#   NB no need to actually use a zero word for LSW of B - just skip
#   additions of A_L + B_L and use R2 in addition of A_H + B_H
# --------------------------------------------------------------
mul16:
                                # Get B into [r2,-]
    mov     r3,r0                   # Get A into [r3,r1]
    mov     r4,r0,-16               # Setup a loop counter
    mov     r5,r0,1                 # Constant 1 for incrementing
    add     r0,r0                   # Clear carry outside of loop - reentry from bottom will always have carry clear
mulstep16:
    ror     r3,r3                   # Shift right A
    ror     r1,r1
    c.add   r3,r2                   # Add [r2,-] + [r3,r1] if carry
    add     r4,r5                   # increment counter
    nz.mov  pc,r0,mulstep16         # next iteration if not zero
    add     r0,r0                   # final shift needs clear carry
    ror     r3,r3
    ror     r1,r1
    mov     pc,r13                  # and return
