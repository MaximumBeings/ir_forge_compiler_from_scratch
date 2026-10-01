#include <stdio.h>
#include <stdint.h>

/* The real five-argument ABI mlir-opt-18's own --finalize-memref-to-llvm
 * pass "unpacked" the single memref<5xi32> argument into: allocated
 * pointer, aligned pointer, offset, and one (size, stride) pair per
 * dimension -- confirmed directly in sum_llvm.mlir's own real output. */
extern int32_t sum_array(int32_t *allocated, int32_t *aligned, int64_t offset,
                          int64_t size0, int64_t stride0);

int main(void) {
    int32_t data[5] = {1, 2, 3, 4, 5};
    int32_t result = sum_array(data, data, 0, 5, 1);
    printf("sum_array({1,2,3,4,5}) = %d\n", result);
    return 0;
}
