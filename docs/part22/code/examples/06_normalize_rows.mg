# Divide each row by its own sum: every row of the result adds up to 1 (a probability-like distribution).
let a = [[1, 1, 2], [5, 0, 5]]
let p = a / row_sum(a)
print p
print row_sum(p)
