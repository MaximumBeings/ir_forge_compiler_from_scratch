# a maximum that is attained twice: the gradient is shared equally between the tied entries (a valid choice; the function has a kink here, so finite differences do not apply).
let m = [[1, 3, 3], [2, 2, 0]]
print col_sum(row_max(m))
