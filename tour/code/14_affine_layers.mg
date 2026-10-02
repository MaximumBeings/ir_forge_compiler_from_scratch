# A function that maps a point by a matrix and a shift, applied twice. Shapes are in the types, so the compiler checks every call.
def affine(x: tensor[2x1], w: tensor[2x2], b: tensor[2x1]) = w @ x + b
let x = [[1], [2]]
let w = [[2, 0], [0, 3]]               # stretch x by 2 and y by 3
let b = [[1], [1]]                     # then shift by (1, 1)
print affine(x, w, b)                  # (2*1+1, 3*2+1) = (3, 7)
print affine(affine(x, w, b), w, b)    # again: (2*3+1, 3*7+1) = (7, 22)
