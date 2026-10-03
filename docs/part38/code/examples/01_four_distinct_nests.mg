# 35 loop nests in `main`: twelve rounds of three operations on two matrices (the very first add, `a + a`, adds a constant to itself and the compiler folds it into a
# constant, so it makes no loop). --outline turns the 35 nests into 35 calls of FOUR functions: a product of a 3 x 3 with ITSELF (the first q), an add on 2 x 2, a product
# of two 3 x 3 matrices, and a transpose of 3 x 3, however many rounds there are. (A function is outlined only when it has at least 32 top-level loop nests.)
let a = [[1, 2], [3, 4]]
let b = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
let p0 = a + a
let q0 = b * b
let r0 = transpose(b)
let p1 = p0 + a
let q1 = q0 * b
let r1 = transpose(r0)
let p2 = p1 + a
let q2 = q1 * b
let r2 = transpose(r1)
let p3 = p2 + a
let q3 = q2 * b
let r3 = transpose(r2)
let p4 = p3 + a
let q4 = q3 * b
let r4 = transpose(r3)
let p5 = p4 + a
let q5 = q4 * b
let r5 = transpose(r4)
let p6 = p5 + a
let q6 = q5 * b
let r6 = transpose(r5)
let p7 = p6 + a
let q7 = q6 * b
let r7 = transpose(r6)
let p8 = p7 + a
let q8 = q7 * b
let r8 = transpose(r7)
let p9 = p8 + a
let q9 = q8 * b
let r9 = transpose(r8)
let p10 = p9 + a
let q10 = q9 * b
let r10 = transpose(r9)
let p11 = p10 + a
let q11 = q10 * b
let r11 = transpose(r10)
print p11
print q3
print r11
