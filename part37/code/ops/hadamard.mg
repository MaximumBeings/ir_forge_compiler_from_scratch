# One operation on 64 x 64 matrices, so the chapter can ask what LLVM makes of its loop.
def f(a: tensor[64x64], b: tensor[64x64]) = a * b
