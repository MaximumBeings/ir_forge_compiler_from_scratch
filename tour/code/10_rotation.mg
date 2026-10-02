# Rotating points by 90 degrees is a matrix product. Each COLUMN of p is one point (x on the top row, y below).
let rotate90 = [[0, -1], [1, 0]]
let p = [[1, 0, -1], [0, 1, 0]]          # three points: (1,0), (0,1), (-1,0)
print rotate90 @ p                       # each point turned a quarter turn counter-clockwise
print rotate90 @ rotate90 @ p            # turned twice = a half turn = every coordinate negated
print -p                                 # the same numbers (a "-0" in the output is negative zero: it equals 0, and the sign of a zero is how floating-point arithmetic remembers which side it came from)
