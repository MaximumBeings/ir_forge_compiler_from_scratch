# every scalar operation, on either side, and negation: the gradient of each term is worked out by the rules, and checked against finite differences.
let x = [[0.7, -1.3, 2.1], [1.4, 0.9, -0.6]]
print col_sum(row_sum((x + 2.0) * 0.5 + (x - 2.0) * 0.25 + (2.0 - x) * 0.125 + (3.0 * x) * 0.0625 + (x / 4.0) + (4.0 / x) * 0.03125 + (-x) * 0.015625))
