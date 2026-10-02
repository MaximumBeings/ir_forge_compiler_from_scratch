// An ordinary C++ program using Mountain Goat functions through the generated header.
#include <cstdio>
#include "kernels.h"

static void show(const char *name, const mg::Matrix &m) {
  std::printf("%s (%ldx%ld):\n", name, (long)m.rows, (long)m.cols);
  for (int64_t i = 0; i < m.rows; i++) {
    for (int64_t j = 0; j < m.cols; j++) std::printf(" %g", m(i, j));
    std::printf("\n");
  }
}

int main(int argc, char **argv) {
  mg::Matrix a(2, 3, {1, 2, 3, 4, 5, 6});
  mg::Matrix b(2, 3, {10, 20, 30, 40, 50, 60});
  show("add(a, b)", mg::add(a, b));
  show("add_t(a, b)", mg::add_t(a, b));
  show("scale2(a)", mg::scale2(mg::scale2(a)));  // results are values, so calls compose
  show("rot(a)", mg::rot(a));                    // static shape 2x3, checked by the header

  // Static shape violated: the C++ wrapper throws before the compiled code runs.
  try { mg::rot(mg::Matrix(3, 2, {1, 2, 3, 4, 5, 6})); }
  catch (const std::invalid_argument &e) { std::printf("caught: %s\n", e.what()); }

  // Dynamic shapes violated: the compiled code's own runtime check aborts (message on stderr).
  if (argc > 1) {
    std::printf("about to add 2x3 and 3x2...\n"); std::fflush(stdout);
    mg::add(a, mg::Matrix(3, 2, {1, 2, 3, 4, 5, 6}));
    std::printf("not reached\n");
  }
  return 0;
}
