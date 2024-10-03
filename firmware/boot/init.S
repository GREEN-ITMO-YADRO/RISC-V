.section .reset, "ax"
.global _reset
.type _reset, @function
_reset:
    la sp, __stack_top
    mv fp, sp
.option push
.option norelax
    la gp, __global_pointer
.option pop
    li s1, 0
    li s2, 0
    li s3, 0
    li s4, 0
    li s5, 0
    li s6, 0
    li s7, 0
    li s8, 0
    li s9, 0
    li s10, 0
    li s11, 0
    j _start
