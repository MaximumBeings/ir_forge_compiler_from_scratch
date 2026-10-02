# Expressions nest and chain: + is left-associative, transpose(...) can wrap anything.
let a = [[1, 2], [3, 4]]
let b = [[10, 20], [30, 40]]
let c = [[100, 200], [300, 400]]
print a + b + c
print transpose(a + transpose(b))
