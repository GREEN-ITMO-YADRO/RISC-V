#include <stdint.h>
#include <stdlib.h>

extern uint32_t __data_rom_start;
extern uint32_t __bss_start;
extern uint32_t __bss_end;
extern uint32_t __data_start;
extern uint32_t __data_end;

[[gnu::section(".trap")]] [[gnu::interrupt("machine")]]
void trap_handler(void) {
    for (;;);
}

extern int main(void);
extern void __libc_init_array(void);
extern void __libc_fini_array(void);

void _start(void) {
    uint32_t *init_values = &__data_rom_start;

    for (uint32_t *data = &__data_start; data < &__data_end; ++data) {
        *data = *(init_values++);
    }

    for (uint32_t *bss = &__bss_start; bss < &__bss_end; ++bss) {
        *bss = 0;
    }

    atexit(__libc_fini_array);
    __libc_init_array();

    exit(main());
}
