# matmul and transpose: loss = sum of transpose(a @ b) * w, with a 2x3 times a 3x2.
let a = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6]]
let b = [[0.5, -0.4], [1.2, 0.9], [-1.1, 0.3]]
let w = [[1.5, -0.5], [0.25, 2.0]]
print col_sum(row_sum(transpose(a @ b) * w))
