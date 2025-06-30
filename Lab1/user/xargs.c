#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"

void run(char* program, char** args) {
    if(fork() == 0) {
        exec(program, args);
        exit(0);
    }
    return;
}

int main(int argc, char** argv) {
    char buf[2048];
    char *p = buf;
    char *last_p = buf;
    char *argbuf[128];
    char **args = argbuf;

    for(int i = 1;i < argc;i++) {
        *args = argv[i];
        args++;
    }

    char **pa = args;

    while(read(0, p, 1)) {
        if(*p == ' ' || *p == '\n') {
            *p = 0;
            *pa = last_p;
            pa++;
            last_p = p + 1;
            if(*p == '\n') {
                *pa = 0;
                run(argv[1], argbuf);
                pa = args;
            }
        }
        p++;
    }

    if(pa != args) {
        *p = 0;
        *pa = last_p;
        pa++;
        *pa = 0;
        run(argv[1], argbuf);
    }

    while(wait(0) != -1);
    exit(0);
}