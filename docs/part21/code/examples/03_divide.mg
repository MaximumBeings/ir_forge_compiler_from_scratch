# Elementwise division, and IEEE behaviour: x/0 is inf, 0/0 is nan (no error, no abort).
let a = [[10, 20], [0, -5]]
let b = [[4, 8], [0, 0]]
print a / b
