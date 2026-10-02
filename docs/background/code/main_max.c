#include <stdio.h>
int max(int, int);                       /* defined in handwritten.ll */
int main(void) { printf("max(3, 9) = %d, max(7, -2) = %d\n", max(3, 9), max(7, -2)); return 0; }
