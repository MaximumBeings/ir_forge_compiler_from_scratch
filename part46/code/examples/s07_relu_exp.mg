# relu times exp: the relu mask matters at BOTH orders here (unlike relu squared, whose relu output is already zero where the mask is): gradient mask*exp(x) + relu(x)*exp(x).
let x = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6]]
print col_sum(row_sum(relu(x) * exp(x)))
