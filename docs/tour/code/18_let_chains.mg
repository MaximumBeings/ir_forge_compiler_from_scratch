# Names let a calculation be built in steps, and each step can be printed. Here: the mean and the spread of one row of numbers.
let x = [[2, 4, 4, 4, 5, 5, 7, 9]]           # 1x8
let mean = row_mean(x)                         # 1x1: 40/8 = 5
let centered = x - mean                        # the 1x1 mean is stretched across all eight
let variance = row_mean(centered * centered)   # 1x1: the mean of the squared distances from the mean = 4
print mean
print centered
print variance
# Shadowing: a new let of an old name does not change the old value; any earlier line already used it.
let variance = variance * variance
print variance                                 # 16: this is the new binding
