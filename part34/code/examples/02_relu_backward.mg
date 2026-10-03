# Backward through relu. y = max(0, p). The derivative is 1 where p is positive and 0 where it is negative, so the gradient d passes through where
# p >= 0 and is cut where p < 0: dp = d * ge(p, 0). (ge is the comparison of Chapter 32; [[0]] is a 1x1 matrix, stretched across the row.)
# At p = 0 exactly the true derivative does not exist (a corner); this program, like most training code, passes the gradient there. The brute-force
# estimate at a corner is the average of the two sides, half of d. The second row shows it.
let p = [[-1.5, 0, 2, 3]]
let d = [[1, 2, 3, 4]]
print d * ge(p, [[0]])
print (row_sum(d * relu(p + [[0.01, 0, 0, 0]])) - row_sum(d * relu(p - [[0.01, 0, 0, 0]]))) / 0.02
print (row_sum(d * relu(p + [[0, 0.01, 0, 0]])) - row_sum(d * relu(p - [[0, 0.01, 0, 0]]))) / 0.02
print (row_sum(d * relu(p + [[0, 0, 0.01, 0]])) - row_sum(d * relu(p - [[0, 0, 0.01, 0]]))) / 0.02
print (row_sum(d * relu(p + [[0, 0, 0, 0.01]])) - row_sum(d * relu(p - [[0, 0, 0, 0.01]]))) / 0.02
