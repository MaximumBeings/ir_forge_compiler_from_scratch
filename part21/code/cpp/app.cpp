// A C++ program calling the Chapter 21 operations. The elementwise results are checked by the test against exact expected
// values; matmul is also compared against a plain C++ triple loop, including after the heap has been deliberately dirtied.
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include "ops.h"

static bool same(const mg::Matrix &x, const mg::Matrix &y) {
  if (x.rows != y.rows || x.cols != y.cols) return false;
  for (size_t i = 0; i < x.data.size(); i++) if (std::fabs(x.data[i] - y.data[i]) > 1e-12) return false;
  return true;
}
static mg::Matrix ref_matmul(const mg::Matrix &a, const mg::Matrix &b) {
  mg::Matrix c(a.rows, b.cols, std::vector<double>(a.rows * b.cols, 0.0));
  for (int64_t i = 0; i < a.rows; i++)
    for (int64_t j = 0; j < b.cols; j++)
      for (int64_t k = 0; k < a.cols; k++) c(i, j) += a(i, k) * b(k, j);
  return c;
}
static void show(const char *name, const mg::Matrix &m) {
  std::printf("%s (%ldx%ld):\n", name, (long)m.rows, (long)m.cols);
  for (int64_t i = 0; i < m.rows; i++) { for (int64_t j = 0; j < m.cols; j++) std::printf(" %g", m(i, j)); std::printf("\n"); }
}

int main(int argc, char **argv) {
  mg::Matrix a(2, 3, {1, 2, 3, 4, 5, 6}), b(3, 2, {7, 8, 9, 10, 11, 12}), c(2, 3, {6, 5, 4, 3, 2, 1});
  show("sub(a, c)", mg::sub(a, c));
  show("hadamard(a, c)", mg::hadamard(a, c));
  show("divide(a, c)", mg::divide(a, c));
  show("matmul(a, b)", mg::matmul(a, b));
  show("gram(a)", mg::gram(a));
  show("affine(a)", mg::affine(a));
  std::printf("matmul matches a plain C++ triple loop: %s\n", same(mg::matmul(a, b), ref_matmul(a, b)) ? "yes" : "NO");
  // Dirty the heap first: allocate a block, fill it with 1000s, free it. The compiled code never zeroes memory it did not
  // fill itself, so a matmul that forgot to zero its accumulators would add into these 1000s and print 1015, 1022 instead of
  // 15, 22. (Without this, a fresh heap is all zeros and the bug hides.)
  {
    double *junk = (double *)std::malloc(4 * sizeof(double));
    for (int i = 0; i < 4; i++) junk[i] = 1000.0;
    std::free(junk);
    mg::Matrix sq(2, 2, {1, 2, 3, 4});
    mg::Matrix r = mg::matmul(sq, sq);
    std::printf("dirty-heap matmul: %g %g %g %g\n", r.data[0], r.data[1], r.data[2], r.data[3]);
  }
  // A bigger one, to compare against the reference on more than a hand-sized case.
  std::vector<double> pd(35), qd(45);
  for (size_t i = 0; i < 35; i++) pd[i] = (double)((i * 7) % 11) - 5;
  for (size_t i = 0; i < 45; i++) qd[i] = (double)((i * 5) % 13) - 6;
  mg::Matrix p(7, 5, pd), q(5, 9, qd);
  std::printf("7x5 @ 5x9 matches the plain loop: %s\n", same(mg::matmul(p, q), ref_matmul(p, q)) ? "yes" : "NO");
  if (argc > 1) {
    std::printf("about to matmul 2x3 by 2x3...\n"); std::fflush(stdout);
    mg::matmul(a, a);
    std::printf("not reached\n");
  }
  return 0;
}
