# a product of two matrices squared elementwise: the Hessian couples entries of a and b.
let a = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6]]
let b = [[0.5, -0.4], [1.2, 0.9], [-1.1, 0.3]]
print col_sum(row_sum((a @ b) * (a @ b)))
