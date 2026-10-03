# a row vector and a column vector broadcast against a matrix, and against each other: gradients must be summed back over the broadcast axes.
let m = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6]]
let r = [[0.5, -0.4, 1.2]]
let c = [[0.9], [-1.1]]
print col_sum(row_sum(m * r + c - r * c))
