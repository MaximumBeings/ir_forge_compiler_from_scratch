# The GPU path for matmul (compile-only). Use:  mgc ptx 13_gpu_matmul.mg
def mm(a: tensor[4x4], b: tensor[4x4]) = a @ b
