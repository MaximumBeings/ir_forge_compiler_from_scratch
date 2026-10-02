#include <stdio.h>
#include <stdint.h>
int64_t sum_to(int64_t);                 /* the function compiled from sum_loop.mlir (index becomes a 64-bit integer) */
int main(void) { printf("sum_to(10) = %ld, sum_to(100) = %ld\n", (long)sum_to(10), (long)sum_to(100)); return 0; }
