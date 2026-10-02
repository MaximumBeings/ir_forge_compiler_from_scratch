// Prints every element of a matrix product in hexadecimal floating point (%a), which shows every bit. The inputs are not
// "nice" numbers (they are not exactly representable and the products round), so a different order of additions would change
// bits. Built once against an ijk library and once against an ikj library; the two outputs must be identical.
#include <cstdio>
#include "ops.h"
int main() {
  const int m = 5, k = 7, n = 4;
  std::vector<double> a(m * k), b(k * n);
  for (int i = 0; i < m * k; i++) a[i] = 0.1 * (i % 13) + 1.0 / (i + 3);
  for (int i = 0; i < k * n; i++) b[i] = 0.7 / (i % 11 + 1) - 0.01 * i;
  mg::Matrix r = mg::matmul(mg::Matrix(m, k, a), mg::Matrix(k, n, b));
  for (double v : r.data) std::printf("%a\n", v);
  return 0;
}
