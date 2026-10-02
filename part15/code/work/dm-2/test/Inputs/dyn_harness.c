#include <stdint.h>
#include <stdio.h>

typedef struct { double *allocated; double *aligned; int64_t offset; int64_t sizes[2]; int64_t strides[2]; } Memref2D;

extern Memref2D add_dyn(double *a0, double *a1, int64_t off0, int64_t s0_0, int64_t s0_1, int64_t st0_0, int64_t st0_1,
                        double *b0, double *b1, int64_t off1, int64_t s1_0, int64_t s1_1, int64_t st1_0, int64_t st1_1);
extern Memref2D t_dyn(double *a0, double *a1, int64_t off0, int64_t s0_0, int64_t s0_1, int64_t st0_0, int64_t st0_1);

static void show(const char *name, Memref2D r) {
  printf("%s -> %ldx%ld:\n", name, (long)r.sizes[0], (long)r.sizes[1]);
  for (int64_t i = 0; i < r.sizes[0]; i++) {
    for (int64_t j = 0; j < r.sizes[1]; j++) printf("%g ", r.aligned[r.offset + i * r.strides[0] + j * r.strides[1]]);
    printf("\n");
  }
}

int main(void) {
  double a[6] = {1, 2, 3, 4, 5, 6}, b[6] = {10, 20, 30, 40, 50, 60};
  show("add 2x3", add_dyn(a, a, 0, 2, 3, 3, 1, b, b, 0, 2, 3, 3, 1));
  show("add 3x2", add_dyn(a, a, 0, 3, 2, 2, 1, b, b, 0, 3, 2, 2, 1));
  show("add 1x6", add_dyn(a, a, 0, 1, 6, 6, 1, b, b, 0, 1, 6, 6, 1));
  show("transpose 2x3", t_dyn(a, a, 0, 2, 3, 3, 1));
  show("transpose 1x6", t_dyn(a, a, 0, 1, 6, 6, 1));
#ifdef STRIDED
  // The same 6 numbers viewed as a 2x3 matrix in COLUMN-major order: strides (1, 2) instead of (3, 1).
  // Logical matrix: [[1,3,5],[2,4,6]]. Only a callee whose type carries strides can honor this.
  show("transpose 2x3 column-major view", t_dyn(a, a, 0, 2, 3, 1, 2));
#endif
  return 0;
}
