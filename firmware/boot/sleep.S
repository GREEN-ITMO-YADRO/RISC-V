.section .text
.global sleep_cycles
sleep_cycles:
    li t0, 4
    addi a0, a0, -4
1:
    ble a0, t0, 2f
    addi a0, a0, -6
    j 1b
2:
    ret
