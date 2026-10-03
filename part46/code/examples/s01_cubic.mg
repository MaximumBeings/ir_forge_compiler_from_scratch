# loss = sum of x*x*x + exp(x) * 0.5: gradient 3x^2 + exp(x)/2, second derivative (diagonal of the Hessian) 6x + exp(x)/2
let x = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6]]
print col_sum(row_sum(x * x * x + exp(x) * 0.5))
