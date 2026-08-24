#include <stdio.h>
#include <unistd.h> // Required for sleep()

int main() {
    printf("Dummy process started. My PID is: %d\n", getpid());
    printf("Waiting in the background. Press Ctrl+C to kill me.\n");

    // Infinite loop that puts the program to sleep for 1 second at a time.
    // Using sleep prevents the program from eating up 100% of your CPU!
    while (1) {
        sleep(1); 
    }

    return 0;
}