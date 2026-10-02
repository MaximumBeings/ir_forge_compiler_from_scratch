# Mean and variance of every column of a data table (rows are samples, columns are measurements), with no loops.
let data = [[1, 10], [2, 20], [3, 30], [4, 40]]    # 4 samples, 2 measurements
let mean = col_mean(data)                           # 1x2: one mean per column
let centered = data - mean                          # 4x2: the 1x2 mean is broadcast down all 4 rows
print mean
print centered
print col_mean(centered * centered)                 # 1x2: the variance of each column (mean of squares of the centered data)
