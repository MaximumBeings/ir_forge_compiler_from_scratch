// Tensor contractions, computed two ways and compared: the definition (contract_reference) and a Mountain Goat matrix product (contract_ttgt).
// The first two cases are the worked examples of the "Tensor Contractions (CPU)" appendix of "CUDA From First Principles".
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include "tensor.h"

static bool same_bits(const Tensor &x, const Tensor &y) {
  return x.shape == y.shape && x.data.size() == y.data.size() && std::memcmp(x.data.data(), y.data.data(), x.data.size() * sizeof(double)) == 0;
}
static std::string shape_str(const std::vector<int> &s) { std::string r = "["; for (size_t i = 0; i < s.size(); i++) r += (i ? "," : "") + std::to_string(s[i]); return r + "]"; }
static void print_matrix(const Tensor &C) {
  for (int i = 0; i < C.shape[0]; i++) { std::printf("   "); for (int j = 0; j < C.shape[1]; j++) std::printf(" %8.2f", C.data[i * C.shape[1] + j]); std::printf("\n"); }
}

// Deterministic, deliberately NOT nice numbers (so a different order of additions would change the last bits).
static Tensor filled(std::vector<int> shape, int seed) {
  Tensor T(std::move(shape));
  for (size_t i = 0; i < T.data.size(); i++) T.data[i] = 0.1 * (double)((i * 7 + seed) % 13) - 0.45 + 1.0 / (double)(i + seed + 3);
  return T;
}

static int failures = 0;
static void check(const char *name, const Tensor &A, const std::vector<int> &aa, const Tensor &B, const std::vector<int> &ab) {
  Tensor ref = contract_reference(A, aa, B, ab), got = contract_ttgt(A, aa, B, ab);
  bool ok = same_bits(ref, got);
  if (!ok) failures++;
  std::printf("  %-42s A%-9s B%-9s -> %-9s matches the definition bit for bit: %s\n", name, shape_str(A.shape).c_str(), shape_str(B.shape).c_str(), shape_str(got.shape).c_str(), ok ? "yes" : "NO");
}

int main(int argc, char **argv) {
  if (argc > 1 && std::strcmp(argv[1], "trap") == 0) {
    // The appendix's trap: contract a [3,2] with a [4,5] over axes of different sizes (2 and 4).
    Tensor A = filled({3, 2}, 1), B = filled({4, 5}, 2);
    std::printf("[3,2] x [4,5] over axis 1 of A (size 2) and axis 0 of B (size 4), with the axis check %s:\n", argc > 2 ? "SKIPPED" : "on");
    if (argc > 2) { std::fflush(stdout); contract_ttgt(A, {1}, B, {0}, /*validate_axes=*/false); std::printf("not reached\n"); return 0; }
    try { contract_ttgt(A, {1}, B, {0}); } catch (const std::invalid_argument &e) { std::printf("  caught std::invalid_argument: \"%s\"\n", e.what()); }
    return 0;
  }

  std::printf("1. Matrix multiply, as contract(A, axis 1, B, axis 0)   (appendix H.3)\n");
  {
    Tensor A({3, 2}), B({2, 4});
    double a[] = {1, 2, 3, 4, 5, 6}, b[] = {1, 0, 2, 1, 0, 1, 1, 2};
    std::copy(a, a + 6, A.data.begin()); std::copy(b, b + 8, B.data.begin());
    Tensor C = contract_ttgt(A, {1}, B, {0});
    std::printf("   C =\n"); print_matrix(C);
    double want[] = {1, 2, 4, 5, 3, 4, 10, 11, 5, 6, 16, 17};
    bool ok = C.shape == std::vector<int>{3, 4} && std::equal(want, want + 12, C.data.begin());
    std::printf("   equals the appendix's numpy-checked values: %s\n", ok ? "yes" : "NO"); if (!ok) failures++;
  }

  std::printf("\n2. A double contraction: [2,3,4] x [3,4,5] over A's axes {1,2} and B's axes {0,1}   (appendix H.4)\n");
  {
    Tensor A({2, 3, 4}), B({3, 4, 5});
    for (size_t i = 0; i < A.data.size(); i++) A.data[i] = (double)(i % 7) - 3.0;
    for (size_t i = 0; i < B.data.size(); i++) B.data[i] = (double)(i % 5) - 2.0;
    Tensor C = contract_ttgt(A, {1, 2}, B, {0, 1});
    {
      // The reshape: A's free axis {0} against its contracted axes {1,2}, and B's contracted axes {0,1} against its free axis {2}.
      long long m = A.shape[0], k = (long long)A.shape[1] * A.shape[2], n = B.shape[2];
      std::printf("   as matrices: %lldx%lld times %lldx%lld  ->  %lld multiply-adds (the appendix's formula T x product of contracted sizes: %lld x %lld = %lld)\n",
                  m, k, k, n, m * n * k, m * n, (long long)B.shape[0] * B.shape[1], m * n * k);
    }
    std::printf("   output shape %s\n   C =\n", shape_str(C.shape).c_str()); print_matrix(C);
    double want[] = {10, 5, 0, -5, -10, 2, 1, 0, -1, -2};
    bool ok = C.shape == std::vector<int>{2, 5} && std::equal(want, want + 10, C.data.begin());
    std::printf("   equals the appendix's numpy.tensordot values: %s\n", ok ? "yes" : "NO"); if (!ok) failures++;
  }

  std::printf("\n3. More contractions, each compared with the definition (bit for bit, on numbers that are not 'nice')\n");
  check("matrix product", filled({3, 2}, 1), {1}, filled({2, 4}, 2), {0});
  check("double contraction", filled({2, 3, 4}, 1), {1, 2}, filled({3, 4, 5}, 2), {0, 1});
  check("contracted axis in the FRONT of A", filled({2, 3, 4}, 3), {0}, filled({2, 5}, 4), {0});
  check("contracted axes listed in reverse order", filled({2, 3, 4}, 5), {2, 1}, filled({4, 3, 5}, 6), {0, 1});
  check("contracted axes in the middle of both", filled({5, 2, 3}, 7), {1, 2}, filled({4, 3, 2, 6}, 8), {2, 1});
  check("vector times matrix", filled({4}, 9), {0}, filled({4, 6}, 10), {0});
  check("dot product (every axis contracted)", filled({2, 3, 4}, 11), {0, 1, 2}, filled({2, 3, 4}, 12), {0, 1, 2});
  check("outer product (no contracted axis)", filled({3}, 13), {}, filled({4}, 14), {});
  check("rank 3 x rank 3, one shared axis", filled({3, 4, 5}, 15), {2}, filled({5, 2, 3}, 16), {0});

  std::printf("\n4. The axis check (appendix H.5): [3,2] x [4,5] over axes of size 2 and 4\n");
  {
    Tensor A = filled({3, 2}, 1), B = filled({4, 5}, 2);
    try { contract_ttgt(A, {1}, B, {0}); std::printf("   NOT rejected: NO\n"); failures++; }
    catch (const std::invalid_argument &e) { std::printf("   rejected, as it should be: \"%s\"\n", e.what()); }
    for (auto bad : std::vector<std::pair<std::vector<int>, std::vector<int>>>{{{1}, {0, 1}}, {{5}, {0}}, {{1, 1}, {0, 1}}}) {
      try { contract_ttgt(A, bad.first, B, bad.second); std::printf("   bad axis list NOT rejected: NO\n"); failures++; }
      catch (const std::invalid_argument &e) { std::printf("   also rejected: \"%s\"\n", e.what()); }
    }
  }

  std::printf("\n%s\n", failures == 0 ? "All checks passed." : "SOME CHECKS FAILED.");
  return failures == 0 ? 0 : 1;
}
