# 'def' declares a function: typed parameters, one expression as the body, the result type is worked out.
def scale(a: tensor[2x2]) = a * 3
def shift_and_scale(a: tensor[2x2]) = scale(a + 1)    # may call functions defined ABOVE it
print shift_and_scale([[1, 2], [3, 4]])
