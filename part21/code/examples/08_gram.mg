# a @ transpose(a) is always square and symmetric (a "Gram matrix"): entry (i,j) = row i . row j.
let a = [[1, 2, 3], [4, 5, 6]]
print a @ transpose(a)
print transpose(a) @ a
