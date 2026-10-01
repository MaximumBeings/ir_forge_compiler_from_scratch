#include <stdint.h>
#include <stdio.h>

typedef struct {
    double *allocated;
    double *aligned;
    int64_t offset;
    int64_t sizes[2];
    int64_t strides[2];
} Memref2D;

extern Memref2D add_tensors(double *allocated0, double *aligned0, int64_t offset0,
                             int64_t size0_0, int64_t size0_1,
                             int64_t stride0_0, int64_t stride0_1,
                             double *allocated1, double *aligned1, int64_t offset1,
                             int64_t size1_0, int64_t size1_1,
                             int64_t stride1_0, int64_t stride1_1);

int main(void) {
    double a[4] = {1.0, 2.0, 3.0, 4.0};
    double b[4] = {5.0, 6.0, 7.0, 8.0};

    Memref2D result = add_tensors(a, a, 0, 2, 2, 2, 1,
                                   b, b, 0, 2, 2, 2, 1);

    printf("add_tensors([[1,2],[3,4]], [[5,6],[7,8]]) =\n");
    for (int64_t i = 0; i < result.sizes[0]; i++) {
        for (int64_t j = 0; j < result.sizes[1]; j++) {
            printf("%g ", result.aligned[i * result.strides[0] + j * result.strides[1]]);
        }
        printf("\n");
    }
    return 0;
}
