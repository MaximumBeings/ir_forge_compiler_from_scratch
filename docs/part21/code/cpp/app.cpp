// A C++ program calling the Chapter 21 operations. Compare every result against plain C++ loops.
#include <cmath>
#include <cstdio>
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
