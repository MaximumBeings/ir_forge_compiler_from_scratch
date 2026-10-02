# Arithmetic is defined on matrices. A rank 3 value must be reshaped (or contracted) first.
let a = reshape([[1, 2, 3, 4, 5, 6, 7, 8]], 2, 2, 2)
print a + a
