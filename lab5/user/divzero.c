#include <stdio.h>
#include <ulib.h>

volatile int zero;

int
main(void) {
    int result;
    int divisor = zero;
    asm volatile("divw %0, %1, %2" : "=r"(result) : "r"(1), "r"(divisor));
    cprintf("value is %d.\n", result);
    panic("FAIL: T.T\n");
}

