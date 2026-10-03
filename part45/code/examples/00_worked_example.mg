# The example the chapter walks through: loss = sum of relu(x @ w) * 2.
let x = [[0.5, -1.0], [2.0, 1.0]]
let w = [[1.0, 2.0], [3.0, 4.0]]
print col_sum(row_sum(relu(x @ w) * 2.0))
