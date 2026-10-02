// Calls @chain with operands whose runtime shapes DISAGREE (a is 2x3, b is 1x2 over a two-element buffer).
// Chapter 14's runtime check must abort the program before any out-of-bounds load; reaching the printf is a failure.
#include <stdint.h>
#include <stdio.h>
typedef struct { double *allocated; double *aligned; int64_t offset; int64_t sizes[2]; int64_t strides[2]; } Memref2D;
extern Memref2D chain(double*,double*,int64_t,int64_t,int64_t,int64_t,int64_t,double*,double*,int64_t,int64_t,int64_t,int64_t,int64_t);
int main(void) {
  double a[6] = {1,2,3,4,5,6}, b[2] = {10,20};
  Memref2D r = chain(a,a,0,2,3,3,1, b,b,0,1,2,2,1);
  printf("returned %ldx%ld (should be unreachable)\n", (long)r.sizes[0], (long)r.sizes[1]);
  return 0;
}
