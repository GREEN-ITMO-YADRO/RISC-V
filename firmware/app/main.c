#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdint.h>

#include "sleep.h"

extern uint32_t volatile __led_start;

#define CPU_FREQ 32768000

int main(void) {
    //puts("hello, rv32i!");

    while (true) {
        for (size_t i = 0; i < 0x100; ++i) {
            __led_start = i;
            // roughly 0.5 s, with 2 cycles per instruction
            sleep_cycles(CPU_FREQ / 2 / 2);
        }
    }

    return 0;
}
