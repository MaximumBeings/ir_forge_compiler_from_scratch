# a reshaped matrix times another, squared elementwise: the adjoint of a sum must be spread over the summed axis (implicit broadcasting hides a missing spread in simple programs, not in this one).
let a = [[0.7, -1.3, 2.1, 0.4], [1.4, 0.2, -0.6, 0.8]]
let b = [[0.5, -0.4], [1.2, 0.9]]
print col_sum(row_sum((reshape(a, 4, 2) @ b) * (reshape(a, 4, 2) @ b)))
