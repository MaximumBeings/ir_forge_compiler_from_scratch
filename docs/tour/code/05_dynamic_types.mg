# '?' in a type means "any size, known only when the program runs". One function, many shapes.
def twice(a: tensor[?x?]) = a + a                      # any rows, any columns
def row_sums(a: tensor[?x3]) = a @ [[1], [1], [1]]     # any rows, but exactly 3 columns
print twice([[1, 2]])
print twice([[1], [2], [3]])
print row_sums([[1, 2, 3], [4, 5, 6]])
