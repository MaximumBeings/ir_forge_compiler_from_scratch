# The GPU path (compile-only) for a layer with broadcast, reduction and relu. Use: mgc ptx 10_gpu_layer.mg
def f(x: tensor[2x3], bias: tensor[1x3]) = row_sum(relu(x + bias))
