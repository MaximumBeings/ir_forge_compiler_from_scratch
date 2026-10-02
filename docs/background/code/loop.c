// A loop. The LLVM IR for it has several basic blocks and, once optimized, a phi instruction.
int sum_to(int n) {
  int total = 0;
  for (int i = 1; i <= n; i++) total += i;
  return total;
}
