#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
extern void nanloop(double *alloc, double *aligned, int64_t off, int64_t size, int64_t stride, int64_t n);
int main(int argc, char **argv) {
  double a[6] = {1, 2, 3, 4, 5, 6};
  if (argc > 1 && strcmp(argv[1], "nan") == 0) a[3] = NAN;
  nanloop(a, a, 0, 6, 1, 6);
  printf("survived: no NaN found\n");
  return 0;
}
