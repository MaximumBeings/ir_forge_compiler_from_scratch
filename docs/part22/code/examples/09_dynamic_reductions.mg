# Reductions work on dynamic shapes: one compiled function, any number of rows or columns.
def totals(a: tensor[?x?]) = row_sum(a)
def peaks(a: tensor[?x?]) = col_max(a)
print totals([[1, 2, 3], [4, 5, 6]])
print totals([[7], [8], [9], [10]])
print peaks([[1, 9], [5, 2], [3, 3]])
print relu(-[[1, 2], [3, 4]] + 2)
