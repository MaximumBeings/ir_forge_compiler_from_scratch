# The appendix's trap. A is 3x2 and B is 4x5; contracting A's axis 1 (size 2) with B's axis 0 (size 4) is impossible. The compiler says so before any code exists.
let a = reshape([[1, 2, 3, 4, 5, 6]], 3, 2)
let b = reshape([[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]], 4, 5)
print contract(a, (1), b, (0))
