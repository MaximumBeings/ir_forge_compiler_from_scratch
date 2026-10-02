// Times one matrix-product implementation at several sizes and checks every result against a reference.
// Built once per variant: -DVARIANT_MG links the Mountain Goat object (mm_dyn, and mm_256 at N=256);
// -DVARIANT_IJK / -DVARIANT_IKJ time a plain C++ triple loop in that loop order. Everything else is identical.
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <string>
#include <vector>

#ifdef VARIANT_MG
// The memref calling convention (Chapters 1, 8, 20): each matrix is (allocated, aligned, offset, size0, size1, stride0, stride1).
struct Desc { double *allocated, *aligned; int64_t offset, sizes[2], strides[2]; };
extern "C" Desc mm_dyn(double*, double*, int64_t, int64_t, int64_t, int64_t, int64_t, double*, double*, int64_t, int64_t, int64_t, int64_t, int64_t);
extern "C" Desc mm_256(double*, double*, int64_t, int64_t, int64_t, int64_t, int64_t, double*, double*, int64_t, int64_t, int64_t, int64_t, int64_t);
#endif

using Clock = std::chrono::steady_clock;
static double seconds(Clock::time_point a, Clock::time_point b) { return std::chrono::duration<double>(b - a).count(); }

static void ref_ijk(const double *a, const double *b, double *c, int n) {
  for (int i = 0; i < n; i++) for (int j = 0; j < n; j++) { double s = 0; for (int k = 0; k < n; k++) s += a[i * n + k] * b[k * n + j]; c[i * n + j] = s; }
}
static void ref_ikj(const double *a, const double *b, double *c, int n) {
  std::fill(c, c + (size_t)n * n, 0.0);
  for (int i = 0; i < n; i++) for (int k = 0; k < n; k++) { double x = a[i * n + k]; for (int j = 0; j < n; j++) c[i * n + j] += x * b[k * n + j]; }
}

// Run `f` (which writes an n*n result into c) enough times to measure, and return per-call seconds for each of `trials` trials.
template <typename F> static std::vector<double> measure(F f, int trials) {
  f();                                              // warm-up (page faults, caches, lazy binding)
  auto t0 = Clock::now(); f(); double one = seconds(t0, Clock::now());
  int reps = std::max(1, (int)std::ceil(0.05 / std::max(one, 1e-9)));   // aim for at least 50 ms per trial
  std::vector<double> t;
  for (int k = 0; k < trials; k++) { auto s = Clock::now(); for (int r = 0; r < reps; r++) f(); t.push_back(seconds(s, Clock::now()) / reps); }
  std::sort(t.begin(), t.end());
  return t;
}

static void report(const char *label, int n, const std::vector<double> &t, bool ok) {
  double med = t[t.size() / 2], mn = t[0], flops = 2.0 * n * n * n;
  std::printf("%-26s N=%-4d  min %9.3f ms  median %9.3f ms  %7.2f GFLOP/s (median)  %s\n", label, n, mn * 1e3, med * 1e3, flops / med / 1e9, ok ? "result ok" : "RESULT WRONG");
}

int main(int argc, char **argv) {
  const char *label = argc > 1 ? argv[1] : "variant";
  int trials = 7;
  for (int n : {64, 128, 256, 512}) {
    std::vector<double> a((size_t)n * n), b((size_t)n * n), c((size_t)n * n), want((size_t)n * n);
    for (size_t i = 0; i < a.size(); i++) { a[i] = (double)((i * 7) % 11) - 5; b[i] = (double)((i * 5) % 13) - 6; }   // small integers: every product and sum is exact
    ref_ijk(a.data(), b.data(), want.data(), n);
    auto same = [&](const double *x) { for (size_t i = 0; i < want.size(); i++) if (x[i] != want[i]) return false; return true; };
#if defined(VARIANT_IJK)
    auto t = measure([&] { ref_ijk(a.data(), b.data(), c.data(), n); }, trials); report(label, n, t, same(c.data()));
#elif defined(VARIANT_IKJ)
    auto t = measure([&] { ref_ikj(a.data(), b.data(), c.data(), n); }, trials); report(label, n, t, same(c.data()));
#elif defined(VARIANT_MG)
    bool ok = true;
    auto run = [&](Desc (*fn)(double*, double*, int64_t, int64_t, int64_t, int64_t, int64_t, double*, double*, int64_t, int64_t, int64_t, int64_t, int64_t)) {
      return [&, fn] { Desc d = fn(a.data(), a.data(), 0, n, n, n, 1, b.data(), b.data(), 0, n, n, n, 1);
                       ok = ok && same(d.aligned + d.offset); std::free(d.allocated); };
    };
    auto t = measure(run(mm_dyn), trials); report((std::string(label) + " (dynamic sizes)").c_str(), n, t, ok);
    if (n == 256) { ok = true; auto t2 = measure(run(mm_256), trials); report((std::string(label) + " (static 256)").c_str(), n, t2, ok); }
#endif
  }
  return 0;
}
