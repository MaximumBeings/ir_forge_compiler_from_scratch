// Chapter 44: times a Mountain Goat matrix product at several sizes and measures how far each result is from a reference computed in long double (80-bit) arithmetic.
// The inputs are NOT small integers (unlike Chapter 24's benchmark, where every sum was exact and no order of additions could show): they are sines and cosines, so the order of
// additions changes the rounding. Printed: best and median time over 7 trials, GFLOP/s, the largest error relative to sum |a||b| (the natural scale of a dot product's rounding), and the number
// of result elements whose bits differ from the same program built WITHOUT fast-math flags (read from the file given as second argument, or written if it does not exist).
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
struct Desc { double *allocated, *aligned; int64_t offset, sizes[2], strides[2]; };
extern "C" Desc mm_dyn(double*, double*, int64_t, int64_t, int64_t, int64_t, int64_t, double*, double*, int64_t, int64_t, int64_t, int64_t, int64_t);
using Clock = std::chrono::steady_clock;
static double seconds(Clock::time_point a, Clock::time_point b) { return std::chrono::duration<double>(b - a).count(); }
int main(int argc, char **argv) {
  const char *label = argc > 1 ? argv[1] : "variant"; const char *dump = argc > 2 ? argv[2] : nullptr;
  std::printf("%-34s %5s %12s %12s %9s %14s %s\n", "variant", "N", "min ms", "median ms", "GFLOP/s", "max error", "elements differing from the file");
  for (int n : {64, 128, 256, 512}) {
    std::vector<double> a((size_t)n * n), b((size_t)n * n);
    for (size_t i = 0; i < a.size(); i++) { a[i] = 3 * std::sin(i * 0.37); b[i] = 2 * std::cos(i * 0.11); }
    auto call = [&] { return mm_dyn(a.data(), a.data(), 0, n, n, n, 1, b.data(), b.data(), 0, n, n, n, 1); };
    Desc d = call(); std::vector<double> got(d.aligned + d.offset, d.aligned + d.offset + (size_t)n * n); std::free(d.allocated);
    double worst = 0;
    for (int i = 0; i < n; i += (n > 128 ? 7 : 1)) for (int j = 0; j < n; j += (n > 128 ? 5 : 1)) {
      long double s = 0, scale = 0; for (int k = 0; k < n; k++) { s += (long double)a[i * n + k] * b[k * n + j]; scale += std::fabs((long double)a[i * n + k] * b[k * n + j]); }
      worst = std::max(worst, (double)(std::fabs((long double)got[i * n + j] - s) / scale));
    }
    long differ = -1;
    if (dump) { char name[512]; std::snprintf(name, sizeof name, "%s.%d", dump, n); FILE *f = std::fopen(name, "rb");
      if (f) { std::vector<double> ref(got.size()); if (std::fread(ref.data(), 8, ref.size(), f) == ref.size()) { differ = 0; for (size_t i = 0; i < got.size(); i++) differ += std::memcmp(&ref[i], &got[i], 8) != 0; } std::fclose(f); }
      else { f = std::fopen(name, "wb"); std::fwrite(got.data(), 8, got.size(), f); std::fclose(f); } }
    auto one = [&] { Desc e = call(); std::free(e.allocated); };
    one(); auto t0 = Clock::now(); one(); double t1 = seconds(t0, Clock::now()); int reps = std::max(1, (int)std::ceil(0.05 / std::max(t1, 1e-9)));
    std::vector<double> t; for (int k = 0; k < 7; k++) { auto s = Clock::now(); for (int r = 0; r < reps; r++) one(); t.push_back(seconds(s, Clock::now()) / reps); }
    std::sort(t.begin(), t.end()); double med = t[3], flops = 2.0 * n * n * n;
    std::printf("%-34s %5d %12.3f %12.3f %9.2f %14.2e %s\n", label, n, t[0] * 1e3, med * 1e3, flops / med / 1e9, worst, differ < 0 ? "(this is the reference file)" : std::to_string(differ).c_str());
  }
}
