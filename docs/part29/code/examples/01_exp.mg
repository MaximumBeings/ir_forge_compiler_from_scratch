# exp(x) applies e^x to every element. Its results are not whole numbers, so the output shows six significant digits.
let a = [[0, 1], [2, -1]]
print exp(a)                              # e^0 = 1, e^1 = 2.71828, e^2 = 7.38906, e^-1 = 0.367879
# exp turns sums into products: e^(x+y) = e^x * e^y. Both lines print the same numbers (to the printed digits).
let x = [[0.5, 1.5]]
let y = [[1, -2]]
print exp(x + y)
print exp(x) * exp(y)
