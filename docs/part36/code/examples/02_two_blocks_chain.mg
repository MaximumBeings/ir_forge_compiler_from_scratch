# Two blocks in a row, each with a residual connection: x1 = x + f1(x), x2 = x1 + f2(x1). Here f1 and f2 are just a scale (x * w1 and x1 * w2), so every
# quantity is a 1 x 3 row and the answer can be checked by hand. By the chain rule dx2/dx = (1 + w1) * (1 + w2): the identity path of each residual lets the gradient
# through unchanged, and each block adds its own contribution. The backward pass works from the last block to the first, one residual at a time:
#     d1 = d2 * (1 + w2)          (gradient with respect to x1)
#     d0 = d1 * (1 + w1)          (gradient with respect to x)
# Here w1 = 0.5 and w2 = -0.25, so the factor is 1.5 * 0.75 = 1.125. The brute-force line nudges x by 0.01 and compares.
def forward(x: tensor[1x3]) = (x + x * 0.5) + (x + x * 0.5) * -0.25
let x = [[1, 2, 3]]
let d2 = [[1, 1, 1]]
let d1 = d2 + d2 * -0.25
let d0 = d1 + d1 * 0.5
print d0
print (forward(x + [[0.01, 0, 0]]) - forward(x - [[0.01, 0, 0]])) / 0.02
