#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

void primes(int p_read) {
    int prime;
    if(read(p_read, &prime, sizeof(int)) != sizeof(int)) {
        exit(0);
    }
    printf("prime %d\n", prime);

    int p[2];
    pipe(p);
    if(fork() == 0) {
        close(p[1]);
        primes(p[0]);
    } else {
        int num;
        while(read(p_read, &num, sizeof(int)) == sizeof(int)) {
            if(num % prime) write(p[1], &num, sizeof(int));
        }
        close(p[1]);
        wait(0);
    }
    exit(0);
}

int main(int argc, char **argv) {
    int p[2];
    pipe(p);

    if(fork() == 0) {
        // child
        close(p[1]);
        primes(p[0]);
    } else {
        for(int i = 2;i <= 35;i++) {
            write(p[1], &i, sizeof(int));
        }
        close(p[1]);
        wait(0);
    }
    exit(0);
}