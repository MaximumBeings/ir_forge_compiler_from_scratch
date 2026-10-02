# A mean divides by a count, and the count of rows is not known when the size is '?'.
def f(a: tensor[?x?]) = row_mean(a)
