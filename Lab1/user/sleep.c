#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char **argv) {
    if(argc < 2) {
        printf("(XIII)usage: sleep <ticks>\n");
    } else sleep(atoi(argv[1]));
    exit(0);
}