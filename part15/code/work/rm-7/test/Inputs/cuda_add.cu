// Equivalent hand-written CUDA-style kernel, compiled without the CUDA SDK.
// 'threadIdx.x'/'blockIdx.x' are NVVM builtins in disguise; we call them directly.
extern "C" __attribute__((global)) void add_cuda(const double *a, const double *b, double *c) {
  int row = __nvvm_read_ptx_sreg_ctaid_x();
  int col = __nvvm_read_ptx_sreg_tid_x();
  int i = row * 2 + col;
  c[i] = a[i] + b[i];
}
