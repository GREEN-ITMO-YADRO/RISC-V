#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-parameter"

#include <errno.h>
#undef errno

#include <sys/stat.h>

extern int errno;
char *__env[1] = {0};
char **environ = __env;

int _close(int file) {
    return -1;
}

int _execve(char *name, char **argv, char **env) {
    errno = ENOMEM;

    return -1;
}

int _fork(void) {
    errno = EAGAIN;

    return -1;
}

int _fstat(int file, struct stat *st) {
    st->st_mode = S_IFCHR;

    return 0;
}

int _getpid(void) {
    return 1;
}

int _isatty(int file) {
    return 1;
}

int _kill(int pid, int sig) {
    errno = EINVAL;

    return -1;
}

int _link(char *old, char *new) {
    errno = EMLINK;

    return -1;
}

int _lseek(int file, int ptr, int dir) {
    return 0;
}

int _open(char const *file, int flags, int mode) {
    return -1;
}

int _read(int file, char *ptr, int len) {
    return 0;
}

caddr_t _sbrk(ptrdiff_t incr) {
    extern char __end;
    extern char __ram_end;

    static char *heap_end = &__end;

    char *prev_end = heap_end;

    if (heap_end + incr > &__ram_end || heap_end + incr < &__end) {
        errno = ENOMEM;

        return (caddr_t) -1;
    }

    heap_end += incr;

    return (caddr_t) prev_end;
}

int _stat(char const *restrict file, struct stat *restrict st) {
    st->st_mode = S_IFCHR;

    return 0;
}

struct tms;

int _times(struct tms *buf) {
    return -1;
}

int _unlink(char *name) {
    errno = ENOENT;

    return -1;
}

int _wait(int *status) {
    errno = ECHILD;

    return -1;
}

int _write(int file, char const *ptr, int len) {
    extern uint32_t volatile __dut_bus_start;

    for (int i = 0; i < len; ++i) {
        __dut_bus_start = ptr[i];
    }

    return len;
}

#pragma GCC diagnostic pop
