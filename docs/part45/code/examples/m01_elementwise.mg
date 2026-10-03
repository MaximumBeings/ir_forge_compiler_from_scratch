# add, sub, mul, div of two matrices (and a scalar add): loss = sum of ((a + b) * (a - b)) / (b * b + 2).
let a = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6]]
let b = [[1.1, 0.4, -0.9], [-0.5, 1.7, 0.8]]
print col_sum(row_sum(((a + b) * (a - b)) / (b * b + 2.0)))
