factorial.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
    # This is a simple ASM program to compute a factorial.
    # The input is present in register a0 and the answer is stored in a0 when the program ends
_start:

    addi t3, x0, 0      # zero out partial result var

    addi t0, a0, -1      #load intial multiplier
    beq t0, x0, done     # done if asked for 1!


    factorial_loop:
        addi t1, t0, 0      # load current multiplier into multiply counter

        mult_loop:
            add t3, t3, a0      #add into result
            addi t1, t1, -1     # decrement mult loop counter
            bne t1, x0, mult_loop # go back if not done yet


        addi a0, t3, 0          # store sub result into return value
        addi t3, x0, 0          # zero out temp var

        addi t0, t0, -1         # subtract one from factorial loop counter
        bne t0, x0, factorial_loop    # go back if we are not done yet

    done:
        beq x0, x0, done

.section .rodata
# if you need any constants
one:    .word 0xffffffff