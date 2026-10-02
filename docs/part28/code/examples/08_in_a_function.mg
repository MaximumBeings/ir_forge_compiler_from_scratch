# A contraction inside a function. Function parameters are matrices, so the function reshapes them; the shapes are checked once, when it is defined.
# It computes the double contraction of a 2x3x4 tensor (passed as a 2x12 matrix) with a 3x4x5 tensor (passed as a 3x20 matrix), for any values.
def double_contraction(a: tensor[2x12], b: tensor[3x20]) = contract(reshape(a, 2, 3, 4), (1, 2), reshape(b, 3, 4, 5), (0, 1))
let a = [[1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2]]
let b = [[1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5], [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5]]
print double_contraction(a, b)        # every output is a sum of 12 products: 12*(i+1)*(k+1) at row i, column k, because b repeats 1..5 along its last axis
