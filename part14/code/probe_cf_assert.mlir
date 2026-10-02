func.func @f(%a: memref<?xf64>, %b: memref<?xf64>) {
  %c0 = arith.constant 0 : index
  %da = memref.dim %a, %c0 : memref<?xf64>
  %db = memref.dim %b, %c0 : memref<?xf64>
  %eq = arith.cmpi eq, %da, %db : index
  cf.assert %eq, "shapes differ"
  return
}
