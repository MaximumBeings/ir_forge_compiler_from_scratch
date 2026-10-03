# reshape between two shapes with the same number of elements, then a product.
let a = [[0.7, -1.3, 2.1, 0.4], [1.4, 0.2, -0.6, 0.8]]
let b = [[0.5, -0.4], [1.2, 0.9]]
print col_sum(row_sum(reshape(a, 4, 2) @ b))
