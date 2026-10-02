// C++ calling the Chapter 22 functions, compared against plain C++ loops on matrices bigger than any example.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include "ops.h"

static mg::Matrix filled(int64_t r, int64_t c, int seed) {
  std::vector<double> d(r * c);
  for (size_t i = 0; i < d.size(); i++) d[i] = (double)(((i + seed) * 37) % 23) - 11.0;
  return mg::Matrix(r, c, d);
}
static bool same(const mg::Matrix &x, const mg::Matrix &y) {
  if (x.rows != y.rows || x.cols != y.cols) return false;
  for (size_t i = 0; i < x.data.size(); i++) if (std::fabs(x.data[i] - y.data[i]) > 1e-9) return false;
  return true;
}
static void report(const char *what, bool ok) { std::printf("%-44s %s\n", what, ok ? "matches" : "DIFFERS"); }

int main() {
  mg::Matrix a = filled(7, 5, 1);
  mg::Matrix r(7, 5, std::vector<double>(35));
  for (size_t i = 0; i < 35; i++) r.data[i] = std::max(a.data[i], 0.0);
  report("relu_m 7x5", same(mg::relu_m(a), r));

  mg::Matrix rs(7, 1, std::vector<double>(7, 0.0));
  for (int64_t i = 0; i < 7; i++) for (int64_t j = 0; j < 5; j++) rs(i, 0) += a(i, j);
  report("row_sums 7x5", same(mg::row_sums(a), rs));

  mg::Matrix cm(1, 5, std::vector<double>(5, -1e300));
  for (int64_t i = 0; i < 7; i++) for (int64_t j = 0; j < 5; j++) cm(0, j) = std::max(cm(0, j), a(i, j));
  report("col_maxes 7x5", same(mg::col_maxes(a), cm));

  mg::Matrix x = filled(4, 6, 2), w = filled(6, 3, 3), b = filled(1, 3, 4), want(4, 3, std::vector<double>(12, 0.0));
  for (int64_t i = 0; i < 4; i++) for (int64_t j = 0; j < 3; j++) {
    double acc = 0; for (int64_t k = 0; k < 6; k++) acc += x(i, k) * w(k, j);
    want(i, j) = std::max(acc + b(0, j), 0.0);
  }
  report("layer: relu(x @ w + bias), 4x6 by 6x3", same(mg::layer(x, w, b), want));

  mg::Matrix m = filled(5, 4, 5), c(5, 4, std::vector<double>(20));
  for (int64_t j = 0; j < 4; j++) {
    double mean = 0; for (int64_t i = 0; i < 5; i++) mean += m(i, j); mean /= 5;
    for (int64_t i = 0; i < 5; i++) c(i, j) = m(i, j) - mean;
  }
  report("center: subtract each column's mean, 5x4", same(mg::center(m), c));
  return 0;
}
