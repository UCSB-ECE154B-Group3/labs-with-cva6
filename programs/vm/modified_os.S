#define USER_PA_1 0x80005000
#define USER_VA_1 0x80001000
#define USER_PA_2 0x80006000
#define USER_VA_2 0x80007000

#define KERNEL_PA 0x80000000
#define PT2_PA 0x80002000
#define PT1_PA 0x80003000
#define PT0_PA 0x80004000

#define PN(PA) (PA >> 12)
#define PN0(PA) (PA >> 12 & 0x1ff)
#define PN1(PA) (PA >> 21 & 0x1ff)
#define PN2(PA) (PA >> 30 & 0x1ff)

.text
.global _start;

_start:

.align 2
bootloader:
        # Init PT2
        li t2, PT2_PA + 8*PN2(PT1_PA);
        li t3, (PN(PT1_PA) << 10) | 0x1; # pointer to PT1
        sw t3, 0(t2);

        # Init PT1
        li t2, PT1_PA + 8*PN1(PT0_PA);
        li t3, (PN(PT0_PA) << 10) | 0x1; # pointer to PT0
        sw t3, 0(t2);

        # Init PT0
        # Set KERNEL_PA->KERNEL_PA
        li t2, PT0_PA + 8*PN0(KERNEL_PA);
        li t3, (PN(KERNEL_PA) << 10) | 0xef;
        sw t3, 0(t2);
        # Set PT2_PA->PT2_PA
        li t2, PT0_PA + 8*PN0(PT2_PA);
        li t3, (PN(PT2_PA) << 10) | 0xef;
        sw t3, 0(t2);
        # Set PT1_PA->PT1_PA
        li t2, PT0_PA + 8*PN0(PT1_PA);
        li t3, (PN(PT1_PA) << 10) | 0xef;
        sw t3, 0(t2);
        # Set PT0_PA->PT0_PA
        li t2, PT0_PA + 8*PN0(PT0_PA);
        li t3, (PN(PT0_PA) << 10) | 0xef;
        sw t3, 0(t2);

        # cfig PMP
        # entry0: addr 0x0_0000_0000~0x2_ffff_ffff, l=0 a=1 x=1 w=1 r=1
        li   x1, 0x0f;
        csrw pmpcfg0, x1;
        li   x1, 0xc0000000;
        csrw pmpaddr0, x1;

# ADDED CODE HERE
        la   t0, m_trap;
        csrw mtvec, t0;         # set trap handler
        
        li      t4, 0x100;
        csrs    medeleg, t4;    # machine exception delegation register

        li      s1, 1;          # init a counter = 1

        # Get into supervisor mode --given code below
        li t4, (1 << 11) | (1 << 5);
        csrw mstatus, t4;
        la t5, OS;
        csrw mepc, t5;
        mret;                   # go to OS

.align 2
m_trap:
        csrr    t0, mepc;
        addi    t0, t0, 4;      # Increment mepc by 4
        csrw    mepc, t0;       # Write back the updated mepc
        csrr    t1, mcause;
        ecall;

.align 2
s_trap:
        # Save necessary registers and the current privilege level
        csrr    t0, sstatus;
        csrr    t1, sepc;
        csrr    t2, scause;
        
        addi    s1, s1, 1;      # counter + 1

.align 2
OS:
        # Enable virtual memory
        li a0, (8 << 60) | PN(PT2_PA);
        csrw satp, a0;
        sfence.vma; # Refetch the SATP register

        la   t0, s_trap;
        csrw stvec, t0;                 # set trap handler

        li t0, 3;
        bne s1, t0, run_program;        # if counter /= 3, go run_program
        ecall;                          # else go M_trap
        
.align 2
run_program:
        # Set USER_VA->USER_PA
        li t0, 2;
        beq s1, t0, setup_program_2;    # if counter == 2, go setup_program_2
        j setup_program_1;              # else go setup_program_1

.align 2
setup_program_1:
        li t2, PT0_PA + 8*PN0(USER_VA_1);
        li t3, (PN(USER_PA_1) << 10) | 0xff;
        sw t3, 0(t2);
        la t0, user_program_1;          # Load the the address to start copying into t0
        la t1, user_program_2;          # Load the address to stop copying into t1
        li t3, USER_VA_1;               # Load the destination address into t3
        li t5, USER_VA_1;
        j setup_program_end;

.align 2 
setup_program_2:
        li t2, PT0_PA + 8*PN0(USER_VA_2);
        li t3, (PN(USER_PA_2) << 10) | 0xff;
        sw t3, 0(t2);
        la t0, user_program_2;          # Load the the address to start copying into t0
        la t1, user_program_end;        # Load the address to stop copying into t1
        li t3, USER_VA_2;               # Load the destination address into t3
        li t5, USER_VA_2;

.align 2 
setup_program_end:
        # Enable writing to User PTE in S-Mode after finished the setup
        li t2, (1 << 18);
        csrs sstatus, t2;
        j copy_code;

.align 2 
copy_code:
        lw t4, 0(t0);                   # Load a word from the user program
        sw t4, 0(t3);                   # Store the word to the destination
        addi t0, t0, 4;                 # Increment the user program address
        addi t3, t3, 4;                 # Increment the destination address
        blt t0, t1, copy_code;          # Repeat until the end of the user program is reached

        # Get into user mode
        csrw    sepc, t5;
        sret;

        .data

.align 2
user_program_1:
        # store 154 at USER_VA_1+0xf00
        li      t0, 0x154a;
        li      t1, USER_VA_1+0xf00;
        sw      t0, 0(t1);
        # load 154a to t2
        lw      t2, 0(t1);
        # exit
        li      a0, 0;
        li      a7, 93;
        # Add addition nop
        nop;nop;nop;nop;  # for better finding U mode in trace_hart file
        ecall;
        

.align 2
user_program_2:
        # store 154 at USER_VA_2+0xf00
        li      t0, 0x154b;
        li      t1, USER_VA_2+0xf00;
        sw      t0, 0(t1);
        # load 154b to t2
        lw      t2, 0(t1);
        # exit
        li      a0, 0;
        li      a7, 93;
        ecall;

.align 2 
user_program_end:

        .section ".tohost","aw",@progbits
        .globl tohost
        .globl fromhost

        .align 6
tohost: .dword 0
        .align 6
fromhost: .dword 0
