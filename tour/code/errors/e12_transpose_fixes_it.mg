# The usual fix for the previous mistake: transpose one side so the inner sizes meet. This one is NOT an error: (2x3) @ (3x2) is 2x2.
let a = [[1, 2, 3], [4, 5, 6]]
print a @ transpose(a)
