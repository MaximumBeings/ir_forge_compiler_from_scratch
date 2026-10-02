# q @ transpose(k) needs q and k to have the same width (the inner sizes of the product). Here q is 3x2 and k is 3x3.
let q = [[1, 0], [0, 1], [1, 1]]
let k = [[1, 0, 0], [0, 1, 0], [1, 1, 1]]
print q @ transpose(k)
