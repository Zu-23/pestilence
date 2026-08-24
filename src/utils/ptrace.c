    #include <sys/ptrace.h>
#include <unistd.h>
#include<stdio.h>

int detect_debugger() {
    if (ptrace(PTRACE_TRACEME, 0, 1, 0) < 0) {
        return 1;
    }
    return 0; 
}