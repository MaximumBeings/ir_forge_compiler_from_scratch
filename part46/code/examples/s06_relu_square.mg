# relu squared (second derivative 2 where the input is positive, 0 where negative), away from the kink.
let x = [[0.7, -1.3, 2.1], [1.4, 0.2, -0.6]]
let w = [[1.5, -0.5, 0.25], [2.0, 1.0, -1.0]]
print col_sum(row_sum(relu(x * w) * relu(x * w)))
