#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char **argv) {
    int pipe_fc[2];
    int pipe_cf[2];
    pipe(pipe_fc);
    pipe(pipe_cf);
    int pid = fork();
    if(pid < 0) {
        printf("(XIII) error fork\n");
    } else if(pid == 0) {
        // child
        char buf;
        read(pipe_fc[0], &buf, 1);
        printf("%d: received ping\n", getpid());

        write(pipe_cf[1], &buf, 1);
        close(pipe_cf[1]);
    } else {
        // father
        write(pipe_fc[1], "1", 1);
        close(pipe_fc[1]);

        char buf;
        read(pipe_cf[0], &buf, 1);
        printf("%d: received pong\n", getpid());
        wait(0);
    }
    close(pipe_cf[0]);
    close(pipe_fc[0]);
    exit(0);
}