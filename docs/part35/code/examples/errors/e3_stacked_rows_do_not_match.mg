# The tokens matrix has one row per token of every stacked sequence (6 here); the mask-row vector must have the same 6 rows. A 4-row one cannot multiply it.
let logits = [[1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3]]
let mr = [[0], [1], [0], [1]]
print logits * mr
