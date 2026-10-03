# divisions, log and sqrt of positive entries.
let p = [[0.7, 1.3, 2.1], [1.4, 0.2, 0.6]]
let q = [[0.5, 1.4, 1.2], [1.1, 0.9, 0.3]]
print col_sum(row_sum(log(p) * sqrt(q) + p / q + (2.0 / p) * 0.25))
