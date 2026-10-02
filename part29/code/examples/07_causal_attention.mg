# Causal (masked) attention: position i may only look at positions 0..i. Add a huge negative number to the scores above the diagonal;
# e^(-1000000000) is exactly 0, so those positions get weight 0 and the rows still sum to 1.
def softmax(s: tensor[3x3]) = exp(s - row_max(s)) / row_sum(exp(s - row_max(s)))
def causal_weights(q: tensor[3x2], k: tensor[3x2], mask: tensor[3x3]) = softmax(q @ transpose(k) * 0.7071067811865476 + mask)
let mask = [[0, -1000000000, -1000000000], [0, 0, -1000000000], [0, 0, 0]]
let q = [[1, 0], [0, 1], [1, 1]]
let k = [[1, 0], [0, 1], [1, 1]]
let v = [[10, 0], [0, 10], [5, 5]]
print causal_weights(q, k, mask)                   # upper triangle exactly 0; row 0 is [1, 0, 0]: position 0 can only see itself
print causal_weights(q, k, mask) @ v               # row 0 of the output is row 0 of v unchanged
