# A residual connection adds a sublayer's output to its input, so the shapes must agree. A 54 x 8 hidden layer cannot be added to a 54 x 4 input.
let x = [[1, 2, 3, 4], [5, 6, 7, 8]]
let hidden = [[1, 2, 3, 4, 5, 6, 7, 8], [1, 2, 3, 4, 5, 6, 7, 8]]
print x + hidden
