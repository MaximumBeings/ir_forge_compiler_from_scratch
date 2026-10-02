# Centering: subtract each column's mean, so every column of the result averages to zero.
let a = [[1, 10], [2, 20], [3, 60]]
let centered = a - col_mean(a)
print centered
print col_sum(centered)
