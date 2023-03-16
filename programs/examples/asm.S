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

# Read_Write_hazard:
Set_up_1:
        la     s0, val2;
Read_Write_hazard:
        div    t0, t2, s0;  # t0 = t2 / s0
        lw     t2, 0(s0);   # load t2's value to the address s0

        nop;nop;nop;nop;

#Write_Write_hazard:
Set_up_2:
        la     s0, val2;
        li     t0, 0x98765432198765;   #ALU
Write_Write_hazard:
        div    t2, t0, s0;  # t2 = t0 / s0
        lw     t2, 0(s0);   # store s0's value to the address t2

#Write_Read_hazard:
Set_up_3:
        la  t4, val20;
Write_Read_hazard:
        div t4, t0, t1;  # t3 = t0 / t4
        lw  t2, 0(t4);   # Load the value at the address t4 into t6

        nop;nop;nop;nop;
#A_branch_miss:
Set_up_4:
        li      t5, 5;
        li      t4, 4;
        li      t3, 3;
        li      t2, 2;
A_branch_miss:
        bne     t5, zero, MISSING;   #CTRL_FLOW
        addi    t4, t5, 1;      #ALU
        addi    t3, t5, 2;      #ALU
        addi    t2, t5, 3;      #ALU
        addi    t6, t5, 4;      #ALU
        j       Queue_Full;

MISSING:
        addi    t6, t5, 55;     #ALU #THIS WILL MISS

#Queue_Full:
Queue_Full:
        # The issue queue full: add a long sequence of dependent instructions
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;
        div t4, t0, t1;

END:
        li      a0, 0;          # set exit value to 0
        li      a7, 93;         # set syscall to `exit`
        ecall;

        .data
        .align 4
# Data segment
WORD_F0: .word 0x431a0000 # 154.0
WORD_F1: .word 0x41700000 #  15.0
val2:    .word 2
val20:   .word 20


        .section ".tohost","aw",@progbits
        .globl tohost
        .globl fromhost

        .align 6
tohost: .dword 0
        .align 6
fromhost: .dword 0
