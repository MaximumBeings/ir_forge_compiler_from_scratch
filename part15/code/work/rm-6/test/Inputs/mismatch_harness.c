#include <stdint.h>
#include <stdio.h>
typedef struct { double *allocated; double *aligned; int64_t offset; int64_t sizes[2]; int64_t strides[2]; } Memref2D;
extern Memref2D add_dyn(double*,double*,int64_t,int64_t,int64_t,int64_t,int64_t,double*,double*,int64_t,int64_t,int64_t,int64_t,int64_t);
int main(void) {
  double a[6] = {1,2,3,4,5,6}, b[2] = {10,20};     // b has only 2 elements
  Memref2D r = add_dyn(a,a,0,2,3,3,1, b,b,0,1,2,2,1); // a is 2x3, b is 1x2: MISMATCHED at runtime
  printf("result %ldx%ld: ", (long)r.sizes[0], (long)r.sizes[1]);
  for (int i = 0; i < 6; i++) printf("%g ", r.aligned[i]);
  printf("\n"); return 0;
}
