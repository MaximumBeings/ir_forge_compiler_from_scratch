# Think in shapes first. Each line below says what shape it has; the compiler checks every one of these claims.
let a = [[1, 2, 3], [4, 5, 6]]          # 2x3
let b = [[1, 0, 2, 1], [0, 1, 1, 2], [1, 1, 0, 0]]   # 3x4
print a @ b                              # (2x3) @ (3x4): the inner 3s meet and vanish -> 2x4
print transpose(a @ b)                   # 2x4 turned on its side -> 4x2
print col_sum(a @ b)                     # one total per column -> 1x4
print row_sum(a @ b)                     # one total per row    -> 2x1
