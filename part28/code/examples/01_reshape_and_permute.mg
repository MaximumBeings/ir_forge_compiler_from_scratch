# Tensors of rank 3 and more. A literal is always a matrix; reshape(x, d0, d1, ...) views its numbers with a new shape (row-major, no data moves).
let a = reshape([[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], [13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]], 2, 3, 4)   # 2 blocks of 3x4
print a
# permute(x, p0, p1, p2): result axis i is input axis pi. Swapping the first two axes gives a 3x2x4 tensor.
print permute(a, 1, 0, 2)
# A "rotation" of the axes (a 3-cycle): result axes are input axes 2, 0, 1, so the shape 2x3x4 becomes 4x2x3.
print permute(a, 2, 0, 1)
# reshape undoes nothing and copies nothing: the same 24 numbers in a 4x6 matrix.
print reshape(a, 4, 6)
