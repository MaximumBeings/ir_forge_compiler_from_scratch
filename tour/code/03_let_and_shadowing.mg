# 'let' binds a name to a value. A later 'let' of the same name replaces it (the old value is untouched).
let a = [[1, 2]]
let a = a * 10                      # the right-hand side still sees the OLD a
let a = a + 1
print a
