# a value used three times receives the SUM of three contributions: loss = sum of x * x * x - x.
let x = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6]]
print col_sum(row_sum(x * x * x - x))
