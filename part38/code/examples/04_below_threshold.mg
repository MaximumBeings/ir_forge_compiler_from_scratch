# Only two loop nests (a product and a transpose; an add of constants would be folded away at compile time and make none): below the threshold of 32, so --outline leaves the function
# alone and no mg_outlined function appears.
let a = [[1, 2], [3, 4]]
let b = a * a
let c = transpose(b)
print c
