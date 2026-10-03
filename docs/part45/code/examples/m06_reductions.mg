# row and column sums, maxima and means (the maxima are unique, so the function is smooth there).
let x = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6], [0.5, 1.9, 1.0]]
print col_sum(row_sum(row_sum(x) * row_max(x) + col_sum(x) * col_max(x) + row_mean(x) + col_mean(x) * 0.5))
