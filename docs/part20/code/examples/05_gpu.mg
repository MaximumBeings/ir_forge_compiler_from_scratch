# The GPU path. Parameters (not constants), so nothing folds away at compile time.
# Use:  mgc ptx 05_gpu.mg      Compile-only: this machine has no GPU.
def add(a: tensor[2x2], b: tensor[2x2]) = a + b
