// Gradient descent for linear regression. The MATH (gradient, update, loss) runs in compiled Mountain Goat (gd.mg);
// the LOOP, the data, and every check live here in C++, because the language has no loops.
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <vector>
#include "gd.h"

// A tiny deterministic random number generator, so the data (and the output) are the same on every run and machine.
static uint64_t state = 88172645463325252ULL;
static double uniform(double lo, double hi) {
  state ^= state << 13; state ^= state >> 7; state ^= state << 17;
  return lo + (hi - lo) * ((state >> 11) * (1.0 / 9007199254740992.0));
}

static const int N = 200, D = 4;                         // 200 samples; 3 features + a constant-1 column for the bias
static const double TRUE_P[D] = {2.0, -3.0, 0.5, 1.0};    // the parameters the data is generated from (last one is the bias)

struct Data { mg::Matrix x, y; };
static Data make_data(double noise) {
  std::vector<double> x(N * D), y(N);
  for (int i = 0; i < N; i++) {
    for (int j = 0; j < D - 1; j++) x[i * D + j] = uniform(-1.0, 1.0);
    x[i * D + (D - 1)] = 1.0;
    double t = 0; for (int j = 0; j < D; j++) t += x[i * D + j] * TRUE_P[j];
    y[i] = t + (noise > 0 ? uniform(-noise, noise) : 0.0);
  }
  return {mg::Matrix(N, D, x), mg::Matrix(N, 1, y)};
}

// The same gradient descent written as plain C++ loops, as an independent check of the compiled version.
static std::vector<double> cpp_descent(const Data &d, double lr, int steps) {
  std::vector<double> p(D, 0.0);
  for (int s = 0; s < steps; s++) {
    std::vector<double> g(D, 0.0);
    for (int i = 0; i < N; i++) {
      double r = -d.y.data[i]; for (int j = 0; j < D; j++) r += d.x.data[i * D + j] * p[j];
      for (int j = 0; j < D; j++) g[j] += d.x.data[i * D + j] * r;
    }
    for (int j = 0; j < D; j++) p[j] -= (2.0 * lr / N) * g[j];
  }
  return p;
}

// The exact least-squares answer from the normal equations (X^T X) p = X^T y, by Gaussian elimination.
static std::vector<double> closed_form(const Data &d) {
  double a[D][D + 1] = {};
  for (int i = 0; i < N; i++) for (int j = 0; j < D; j++) {
    for (int k = 0; k < D; k++) a[j][k] += d.x.data[i * D + j] * d.x.data[i * D + k];
    a[j][D] += d.x.data[i * D + j] * d.y.data[i];
  }
  for (int c = 0; c < D; c++) {
    int piv = c; for (int r = c + 1; r < D; r++) if (std::fabs(a[r][c]) > std::fabs(a[piv][c])) piv = r;
    for (int k = 0; k <= D; k++) std::swap(a[c][k], a[piv][k]);
    for (int r = 0; r < D; r++) if (r != c) { double f = a[r][c] / a[c][c]; for (int k = c; k <= D; k++) a[r][k] -= f * a[c][k]; }
  }
  std::vector<double> p(D); for (int j = 0; j < D; j++) p[j] = a[j][D] / a[j][j];
  return p;
}

// The mean squared error computed with plain loops, to check the compiled loss_sum independently.
static double cpp_loss(const Data &d, const std::vector<double> &p) {
  double sum = 0;
  for (int i = 0; i < N; i++) { double r = -d.y.data[i]; for (int j = 0; j < D; j++) r += d.x.data[i * D + j] * p[j]; sum += r * r; }
  return sum / N;
}
static double max_abs_diff(const std::vector<double> &a, const std::vector<double> &b) {
  double m = 0; for (size_t i = 0; i < a.size(); i++) m = std::max(m, std::fabs(a[i] - b[i])); return m;
}
static double mean_loss(const Data &d, const mg::Matrix &p) { return mg::loss_sum(d.x, d.y, p).data[0] / N; }
static void show(const char *label, const std::vector<double> &p) {
  std::printf("  %-34s", label); for (double v : p) std::printf(" %9.5f", v); std::printf("\n");
}

// Run `steps` updates in compiled Mountain Goat, returning the final parameters; losses[s] is the mean squared error before step s.
static mg::Matrix descend(const Data &d, double lr, int steps, std::vector<double> &losses,
                          std::vector<std::vector<double>> *trajectory = nullptr) {   // trajectory[s] = parameters after s steps
  mg::Matrix p(D, 1, std::vector<double>(D, 0.0));
  mg::Matrix rate(1, 1, {2.0 * lr / N});                 // the update is  p - (2 lr / N) * x^T (x p - y)
  for (int s = 0; s <= steps; s++) {
    losses.push_back(mean_loss(d, p));
    if (trajectory) trajectory->push_back(p.data);
    if (s < steps) p = mg::step(d.x, d.y, p, rate);
  }
  return p;
}

int main() {
  const double lr = 0.2; const int steps = 300;
  std::printf("true parameters (w1 w2 w3 bias):  ");  for (double v : TRUE_P) std::printf(" %9.5f", v); std::printf("\n\n");

  // ---- A: no noise. Gradient descent must recover the true parameters, and the loss must fall at every step. ----
  std::printf("A. noise-free data, learning rate %.2f, %d steps\n", lr, steps);
  Data a = make_data(0.0);
  std::vector<double> la; std::vector<std::vector<double>> traj; mg::Matrix pa = descend(a, lr, steps, la, &traj);
  std::printf("  mean squared error at steps:");
  for (int s : {0, 1, 2, 5, 10, 20, 50, 100, 200, 300}) std::printf("  [%d] %.3e", s, la[s]);
  std::printf("\n");
  show("learned (Mountain Goat)", pa.data);
  bool monotone = true; for (size_t s = 1; s < la.size(); s++) if (!(la[s] < la[s - 1]) && la[s - 1] > 1e-25) monotone = false;
  std::printf("  loss fell at every step: %s\n", monotone ? "yes" : "NO");
  std::printf("  parameters recovered to within 1e-6 of the truth: %s\n", max_abs_diff(pa.data, std::vector<double>(TRUE_P, TRUE_P + D)) < 1e-6 ? "yes" : "NO");
  std::printf("  matches the plain C++ gradient descent to within 1e-9: %s\n", max_abs_diff(pa.data, cpp_descent(a, lr, steps)) < 1e-9 ? "yes" : "NO");
  // The end state alone cannot tell a correct gradient from one that is, say, twice too big (both converge to the same answer),
  // so also compare the first steps one at a time: the size of every early step depends on getting the gradient exactly right.
  bool early = true; for (int k = 1; k <= 5; k++) if (max_abs_diff(traj[k], cpp_descent(a, lr, k)) > 1e-12) early = false;
  std::printf("  the first 5 steps match plain C++ step for step to within 1e-12: %s\n", early ? "yes" : "NO");
  std::printf("  the compiled loss equals a plain C++ loss (at the start and the end): %s\n",
              std::fabs(la[0] - cpp_loss(a, std::vector<double>(D, 0.0))) < 1e-9 * la[0] && std::fabs(la.back() - cpp_loss(a, pa.data)) < 1e-12 ? "yes" : "NO");

  // ---- B: noisy data. The truth is no longer the best fit; the best fit is the least-squares (closed-form) answer. ----
  std::printf("\nB. noisy data (noise up to +-0.2), learning rate %.2f, %d steps\n", lr, steps);
  Data b = make_data(0.2);
  std::vector<double> lb; mg::Matrix pb = descend(b, lr, steps, lb);
  std::vector<double> best = closed_form(b);
  show("learned (Mountain Goat)", pb.data);
  show("exact least squares (closed form)", best);
  show("true parameters", std::vector<double>(TRUE_P, TRUE_P + D));
  std::printf("  final mean squared error: %.5f (the noise alone would give about %.5f = 0.2^2/3)\n", lb.back(), 0.2 * 0.2 / 3);
  std::printf("  gradient descent matches the exact least-squares answer to within 1e-6: %s\n", max_abs_diff(pb.data, best) < 1e-6 ? "yes" : "NO");
  std::printf("  the compiled loss equals a plain C++ loss on the noisy data: %s\n", std::fabs(lb.back() - cpp_loss(b, pb.data)) < 1e-12 ? "yes" : "NO");
  std::printf("  closer to the exact answer than to the truth: %s\n", max_abs_diff(pb.data, best) < max_abs_diff(pb.data, std::vector<double>(TRUE_P, TRUE_P + D)) ? "yes" : "NO");

  // ---- C: a learning rate that is too large makes gradient descent diverge. ----
  const double bad = 1.2;
  std::printf("\nC. noise-free data, learning rate %.2f (too large), 12 steps\n", bad);
  std::vector<double> lc; descend(a, bad, 12, lc);
  std::printf("  mean squared error at steps:"); for (int s : {0, 1, 2, 4, 8, 12}) std::printf("  [%d] %.3e", s, lc[s]); std::printf("\n");
  std::printf("  the loss grew instead of shrinking: %s\n", lc[12] > 100 * lc[0] ? "yes" : "NO");
  return 0;
}
