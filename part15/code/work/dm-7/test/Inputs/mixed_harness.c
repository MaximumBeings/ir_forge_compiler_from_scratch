#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
typedef struct { double *allocated; double *aligned; int64_t offset; int64_t sizes[2]; int64_t strides[2]; } Memref2D;
extern Memref2D mixed(double*,double*,int64_t,int64_t,int64_t,int64_t,int64_t,double*,double*,int64_t,int64_t,int64_t,int64_t,int64_t);
int main(int argc, char **argv) {
  int rows = argc > 1 ? atoi(argv[1]) : 3;            // rows of the dynamic operand; the static one always has 3
  double a[16] = {1,2,3,4,5,6,7,8}, b[6] = {10,20,30,40,50,60};
  Memref2D r = mixed(a,a,0,rows,2,2,1, b,b,0,3,2,2,1);
  printf("mixed with a=%dx2, b=3x2 -> %ldx%ld:", rows, (long)r.sizes[0], (long)r.sizes[1]);
  for (int i = 0; i < r.sizes[0]*r.sizes[1]; i++) printf(" %g", r.aligned[i]);
  printf("\n"); return 0;
}
