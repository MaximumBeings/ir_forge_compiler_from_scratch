# The GPU path for the elementwise and scalar ops (compile-only). Use:  mgc ptx 14_gpu_ops.mg
def f(a: tensor[2x2], b: tensor[2x2]) = (a - b) * a / 2 + 1
