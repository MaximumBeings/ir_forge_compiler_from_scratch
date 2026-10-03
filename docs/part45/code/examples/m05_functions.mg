# exp, log, sqrt and relu (inputs chosen away from the kink of relu and from the singularities of log and sqrt).
let p = [[0.7, 1.3, 2.1], [1.4, 0.2, 0.6]]
let q = [[0.5, -0.4, 1.2], [-1.1, 0.9, -0.3]]
print col_sum(row_sum(exp(q) * 0.5 + log(p) * 0.25 + sqrt(p) * 0.125 + relu(q) * 2.0))
