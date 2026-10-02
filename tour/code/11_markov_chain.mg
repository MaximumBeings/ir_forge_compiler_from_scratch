# A two-state weather model. Row i of t says: if today is state i, the chance tomorrow is each state. Each row adds up to 1.
let t = [[0.9, 0.1], [0.5, 0.5]]         # state 0 = sunny, state 1 = rainy
let today = [[1, 0]]                     # it is sunny today (a 1x2 row of probabilities)
print today @ t                          # tomorrow:        [0.9, 0.1]
print today @ t @ t                      # the day after:   [0.86, 0.14]
let t2 = t @ t
let t4 = t2 @ t2
let t8 = t4 @ t4                         # eight steps at once, by repeated squaring: three products instead of seven
print today @ t8                         # drifting toward the long-run mix of 5/6 sunny, 1/6 rainy
