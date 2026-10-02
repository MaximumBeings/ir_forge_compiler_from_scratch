#include <stdint.h>
#include <stdio.h>
typedef struct { double *allocated; double *aligned; int64_t offset; int64_t sizes[2]; int64_t strides[2]; } Memref2D;
extern Memref2D add_dyn(double*,double*,int64_t,int64_t,int64_t,int64_t,int64_t,double*,double*,int64_t,int64_t,int64_t,int64_t,int64_t);
int main(void) {
  double a[6] = {1,2,3,4,5,6}, b[4] = {10,20,30,40};
  // Rows agree (2 == 2), COLUMNS do not (3 vs 2): only a dimension-1 check can catch this.
  Memref2D r = add_dyn(a,a,0,2,3,3,1, b,b,0,2,2,2,1);
  printf("returned %ldx%ld (should be unreachable)\n", (long)r.sizes[0], (long)r.sizes[1]);
  return 0;
}
