        .text
# Text segment
        .globl _start;
_start: # entry point
        li      t0, 0;
        li      t3, 6;
        
lable0:
        li      t1, 2000; // index x, way 1
        jal     lable1;
        .align 16
lable1:       
        li      t1, 2001; // index x, way 2
        jal     lable2;
        .align 16
lable2:
        li      t1, 2002; // index x, way 3
        jal     lable3;
        .align 16
lable3:
        li      t1, 2003; // index x, way 4
        jal     lable4;
        .align 16
lable4:
        li      t1, 2004; // index x, way ?
        addi     t0, t0, 1; # t0++
        beq     t0, t3, done; # if t0 == t3(6) then target
        jal     lable0;    # else  lable0
        .align 16
done:
        li      a0, 0;  # set exit value to 0
        li      a7, 93; # set syscall to `exit`
        ecall;
        .data

//arr: .asciz "Hello, world!"


        .section ".tohost","aw",@progbits
        .globl tohost
        .globl fromhost

        .align 6
tohost: .dword 0
        .align 6
fromhost: .dword 0
