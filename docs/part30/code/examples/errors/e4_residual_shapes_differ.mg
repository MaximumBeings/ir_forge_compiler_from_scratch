# A residual connection adds the sublayer's output to its input, so their shapes must be equal. A 4x2 head output cannot be added to a 4x4 input.
let x = [[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]
let head_output = [[1, 0], [0, 1], [1, 1], [0, 0]]
print x + head_output
