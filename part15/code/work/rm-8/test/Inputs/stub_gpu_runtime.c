// A CPU stand-in for MLIR's GPU runtime wrappers (the mgpu* entry points the lowered host code calls).
// There is no GPU here, so "device memory" is malloc and the "kernel" is a C function that reads the
// SAME launch parameters the PTX reads (params 0, 1, 3, 10, 17) and does the same arithmetic.
// This checks the HOST side (allocation, copies, launch geometry, 23-parameter packing). It does NOT
// execute the PTX, so it says nothing about whether the PTX itself is correct.
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void *mgpuStreamCreate(void) { fprintf(stderr, "[stub] stream create\n"); return malloc(1); }
void mgpuStreamDestroy(void *s) { free(s); }
void mgpuStreamSynchronize(void *s) { (void)s; }
void *mgpuMemAlloc(uint64_t n, void *s, int shared) { (void)s; (void)shared; fprintf(stderr, "[stub] alloc %llu bytes\n", (unsigned long long)n); return malloc(n); }
void mgpuMemFree(void *p, void *s) { (void)s; free(p); }
void mgpuMemcpy(void *dst, void *src, uint64_t n, void *s) { (void)s; fprintf(stderr, "[stub] memcpy %llu bytes\n", (unsigned long long)n); memcpy(dst, src, n); }

static const char *kernel_name_loaded;
void *mgpuModuleLoadJIT(void *ptx, int optLevel) {
  const char *p = (const char *)ptx;
  fprintf(stderr, "[stub] module load: optLevel=%d, PTX has .entry add_tensors_kernel: %s\n", optLevel,
          strstr(p, ".entry add_tensors_kernel") ? "yes" : "NO");
  return (void *)p;
}
void *mgpuModuleGetFunction(void *mod, const char *name) { (void)mod; kernel_name_loaded = name; return (void *)name; }
void mgpuModuleUnload(void *mod) { (void)mod; }

void mgpuLaunchKernel(void *fn, intptr_t gx, intptr_t gy, intptr_t gz, intptr_t bx, intptr_t by, intptr_t bz,
                      int32_t smem, void *stream, void **params, void **extra, size_t nparams) {
  (void)gy; (void)gz; (void)by; (void)bz; (void)smem; (void)stream; (void)extra;
  fprintf(stderr, "[stub] launch %s: grid=(%ld,1,1) block=(%ld,1,1) nparams=%zu\n", (const char *)fn, (long)gx, (long)bx, nparams);
  // Two parameter layouts, depending on the kernel calling convention the host was compiled with:
  //   23 = memref descriptors expanded (default); 5 = bare pointers (kernel-bare-ptr-calling-convention).
  if (nparams != 23 && nparams != 5) { fprintf(stderr, "[stub] unexpected parameter count\n"); exit(2); }
  int64_t step = *(int64_t *)params[0], lb = *(int64_t *)params[1];
  double *a, *b, *c;
  if (nparams == 23) { a = *(double **)params[3]; b = *(double **)params[10]; c = *(double **)params[17]; }
  else               { a = *(double **)params[2]; b = *(double **)params[3];  c = *(double **)params[4]; }
  for (intptr_t blk = 0; blk < gx; blk++)
    for (intptr_t t = 0; t < bx; t++) {
      int64_t i = (blk * step + lb) * 2 + t;
      c[i] = a[i] - b[i];
    }
}
