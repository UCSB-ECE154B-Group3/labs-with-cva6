        .text
# Text segment
        .globl _start;
_start: # entry point

# Out-of-Order Execution:

        #  enable FPU 
        li      t0, (3 << 13);  #ALU
        csrs    mstatus, t0;    #CSR

        # load all the values before running the instructions
        li      t0, 0x98765432198765;   #ALU
        li      t1, 0x123456789;        #ALU

        # load floats into f0 and f1
        la      t2, WORD_F0;    #ALU
        flw     f0, 0(t2);      
        la      t2, WORD_F1;    #ALU
        flw     f1, 0(t2);

        div     t3, t0, t1;     #MULT
        fadd.s  f2, f0, f1;     #FPU #THIS will happen 1st before the div
        lw      t5, 0(zero);    #LSU #THIS will happen 2nd before the div


##      Load immediate set up
        li  t0, 5;
        li  t1, 7;
##      end set up

# # Read-Write hazard:
        add t0, t0, t1;  # t0 = t0 + t1
        sw  t0, 0(t0);   # Store t0's value to the address t0

##      Load immediate set up
        li  t2, 10;
        li  t3, 15;
##      end set up

# Write-Write hazard
        add t2, t2, t3;  # t2 = t2 + t3
        add t2, t2, t3;  # t2 = t2 + t3. overwriting the previous value

##      Load immediate set up
        li  t4, 20;
        li  t5, 2;
##      end set up

# Write-Read hazard
        add t4, t4, t5;  # t4 = t4 + t5
        lw  t6, 0(t4);   # Load the value at the address t4 into t6


# A branch miss:
        beq     t5, zero, MISSING;   #CTRL_FLOW
        addi    t6, t5, 1;      #ALU
        j       END;

MISSING:
        addi    t6, t5, 55;     #ALU #THIS WILL MISS

END:
        # The issue queue full: add a long sequence of dependent instructions
        addi    t1, zero, 1;    #ALU
        addi    t2, t1, 2;      #ALU
        addi    t3, t2, 3;      #ALU
        addi    t4, t3, 4;      #ALU
        addi    t5, t4, 5;      #ALU
        addi    t6, t5, 6;      #ALU
        addi    t1, t6, 7;      #ALU
        addi    t2, t1, 8;      #ALU
        addi    t3, t2, 9;      #ALU
        addi    t4, t3, 10;     #ALU
        addi    t5, t4, 11;     #ALU
        addi    t6, t5, 12;     #ALU

        li      a0, 0;          # set exit value to 0
        li      a7, 93;         # set syscall to `exit`
        ecall;

        .data
# Data segment
WORD_F0: .word 0x431a0000 # 154.0
WORD_F1: .word 0x41700000 #  15.0

        .section ".tohost","aw",@progbits
        .globl tohost
        .globl fromhost

        .align 6
tohost: .dword 0
        .align 6
fromhost: .dword 0
