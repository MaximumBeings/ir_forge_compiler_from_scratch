# permute needs every axis exactly once: a rank 3 tensor has axes 0, 1, 2 and this list repeats one and omits another.
let a = reshape([[1, 2, 3, 4, 5, 6, 7, 8]], 2, 2, 2)
print permute(a, 0, 0, 2)
