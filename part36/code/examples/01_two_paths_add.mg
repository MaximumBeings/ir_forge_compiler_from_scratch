# Fan-out: one matrix u feeds TWO different maps (as a block's normalised input feeds two attention heads). If the loss is
#     L = sum(r1 * (u @ wa)) + sum(r2 * (u @ wb))
# for fixed matrices r1, r2, then u affects L along two routes, and the gradient with respect to u is the SUM of the gradients along them:
#     dL/du = r1 @ transpose(wa) + r2 @ transpose(wb)
# (the same rule that makes a residual connection add, and that adds the three routes q, k, v into one layer norm in Chapter 35).
# The first matrix is that formula. The next four are two entries of u, found by brute force: nudge the entry by 0.01 up and down and watch L change.
def loss(u: tensor[2x2], wa: tensor[2x2], wb: tensor[2x2], r1: tensor[2x2], r2: tensor[2x2]) = col_sum(row_sum(r1 * (u @ wa))) + col_sum(row_sum(r2 * (u @ wb)))
let u = [[1, 2], [3, 4]]
let wa = [[1, 0], [2, 1]]
let wb = [[0, 3], [1, 1]]
let r1 = [[1, 2], [0, 1]]
let r2 = [[2, 0], [1, 1]]
print r1 @ transpose(wa) + r2 @ transpose(wb)
print (loss(u + [[0.01, 0], [0, 0]], wa, wb, r1, r2) - loss(u - [[0.01, 0], [0, 0]], wa, wb, r1, r2)) / 0.02
print (loss(u + [[0, 0.01], [0, 0]], wa, wb, r1, r2) - loss(u - [[0, 0.01], [0, 0]], wa, wb, r1, r2)) / 0.02
print (loss(u + [[0, 0], [0.01, 0]], wa, wb, r1, r2) - loss(u - [[0, 0], [0.01, 0]], wa, wb, r1, r2)) / 0.02
print (loss(u + [[0, 0], [0, 0.01]], wa, wb, r1, r2) - loss(u - [[0, 0], [0, 0.01]], wa, wb, r1, r2)) / 0.02
# The four brute-force numbers are the four entries of the formula's matrix, read in the order (0,0), (0,1), (1,0), (1,1). Using only one of the two terms would be wrong
# for every entry.
