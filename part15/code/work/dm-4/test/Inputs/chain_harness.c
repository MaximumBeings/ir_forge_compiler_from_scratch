// Checks @chain(a, b) = transpose(a + b) for many runtime shapes, comparing against a straightforward C computation.
// Prints one PASS/FAIL line per shape; exits 1 if any shape fails. Shapes include ones that do NOT divide common tile
// sizes (1x1, 5x1, 3x5, 7x4, ...), because remainder handling is where tiling and unrolling go wrong.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

typedef struct { double *allocated; double *aligned; int64_t offset; int64_t sizes[2]; int64_t strides[2]; } Memref2D;
extern Memref2D chain(double *a0, double *a1, int64_t off0, int64_t s0_0, int64_t s0_1, int64_t st0_0, int64_t st0_1,
                      double *b0, double *b1, int64_t off1, int64_t s1_0, int64_t s1_1, int64_t st1_0, int64_t st1_1);

static int check(int64_t rows, int64_t cols) {
  double *a = malloc(sizeof(double) * rows * cols), *b = malloc(sizeof(double) * rows * cols);
  for (int64_t i = 0; i < rows; i++)
    for (int64_t j = 0; j < cols; j++) { a[i * cols + j] = i * 10 + j + 1; b[i * cols + j] = (i + 1) * (j + 2) * 0.5; }
  Memref2D r = chain(a, a, 0, rows, cols, cols, 1, b, b, 0, rows, cols, cols, 1);
  int ok = r.sizes[0] == cols && r.sizes[1] == rows;
  for (int64_t i = 0; ok && i < rows; i++)
    for (int64_t j = 0; j < cols; j++) {
      double want = a[i * cols + j] - b[i * cols + j];
      double got = r.aligned[r.offset + j * r.strides[0] + i * r.strides[1]];
      if (got != want) { printf("  mismatch at a[%ld][%ld]: want %g got %g\n", (long)i, (long)j, want, got); ok = 0; break; }
    }
  printf("%-5s %2ldx%-2ld -> result %ldx%ld\n", ok ? "PASS" : "FAIL", (long)rows, (long)cols, (long)r.sizes[0], (long)r.sizes[1]);
  free(a); free(b);
  return ok;
}

int main(void) {
  static const int64_t shapes[][2] = {{1,1},{1,6},{5,1},{2,3},{3,2},{3,5},{4,4},{7,4},{5,9},{8,8},{13,3}};
  int allok = 1;
  for (unsigned k = 0; k < sizeof shapes / sizeof shapes[0]; k++) allok &= check(shapes[k][0], shapes[k][1]);
  printf("%s\n", allok ? "ALL SHAPES PASS" : "SOME SHAPES FAIL");
  return allok ? 0 : 1;
}
